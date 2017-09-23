local queue  = require 'queue'
local spacer = require 'spacer'
local json   = require 'json'
local uuid   = require 'uuid'
local fiber  = require 'fiber'

local log = require 'log'

local M = {}

function M.take()
	local task = queue.tube.refresh_token:take(10)
	log.info(task)
	if not task then
		log.info('No task')
		return nil
	else
		log.info('Return task')
		return box.tuple.new{ task[1], task[3] }
	end
end

function M.release(taskid)
	queue.tube.refresh_token:release({taskid}, { delay = 10 })
end

function M.ack(taskid, data)
	log.info(json.encode(data))

	local expires = data.expires
	if expires == 0 then
		expires = -1ULL
	else
		expires = fiber.time() + expires
	end

	box.space.tokens:insert(T.tokens.tuple {
		uuid    = uuid.str();
		ctime   = fiber.time();
		atime   = fiber.time();
		token   = data.token;
		expires = expires;
		user_id = tonumber(data.user_id);
	})

	queue.tube.refresh_token:ack(taskid)
end

return M