scriptId = 'com.thalmic.scripts.solidworks'

-- Effects

function killAll()
	myo.keyboard("escape","press")
end

	-- Zoom
function zoomIn()
	myo.keyboard("left_shift", "down")
	myo.keyboard("z", "press")
	myo.keyboard("left_shift", "up")
end

function zoomOut()
	myo.keyboard("z", "press")
end

	-- Rotate
function rotate()
	myo.centerMousePosition()
	myo.mouse("center", "down")
	myo.controlMouse(true)
end

	-- Pan
function pan()
	myo.centerMousePosition()
	myo.keyboard("left_control","down")
	myo.mouse("center", "down")
	myo.controlMouse(true)
end	

-- Burst forward or backward depending on the value of shuttleDirection.

function shuttleBurst()
    if shuttleDirection == "In" then
        zoomIn()
    elseif shuttleDirection == "Out" then
        zoomOut()
    end
end

-- Rotate depending on pose

function objectRotate()
	if shuttleRotate == "Yes" then
		rotate()
	end
end

-- Pan depending on pose

function objectPan()
	if shuttlePan == "Yes" then
		pan()
	end
end

-- Helpers

-- Makes use of myo.getArm() to swap wave out and wave in when the armband is being worn on
-- the left arm. This allows us to treat wave out as wave right and wave in as wave
-- left for consistent direction. The function has no effect on other poses.
function conditionallySwapWave(pose)
    if myo.getArm() == "left" then
        if pose == "waveIn" then
            pose = "waveOut"
        elseif pose == "waveOut" then
            pose = "waveIn"
        end
    end
    return pose
end

-- Unlock mechanism

function unlock()
    unlocked = true
    extendUnlock()
end

function extendUnlock()
    unlockedSince = myo.getTimeMilliseconds()
end


-- Implement Callbacks

function onPoseEdge(pose, edge)
    -- Unlock
    if pose == "thumbToPinky" then
        if edge == "off" then
            -- Unlock when pose is released in case the user holds it for a while.
            unlock()
        elseif edge == "on" and not unlocked then
            -- Vibrate twice on unlock.
            -- We do this when the pose is made for better feedback.
            myo.vibrate("short")
            myo.vibrate("short")
            extendUnlock()
        end
    end

    -- In/Out and shuttle.
    if pose == "waveIn" or pose == "waveOut" then
        local now = myo.getTimeMilliseconds()

        if unlocked and edge == "on" then
            -- Deal with direction and arm.
            pose = conditionallySwapWave(pose)

            -- Determine direction based on the pose.
            if pose == "waveIn" then
                shuttleDirection = "In"
            else
                shuttleDirection = "Out"
            end

            -- Initial burst and vibrate
            myo.vibrate("short")
            shuttleBurst()

            -- Set up shuttle behaviour. Start with the longer timeout for the initial
            -- delay.
            shuttleSince = now
            shuttleTimeout = SHUTTLE_CONTINUOUS_TIMEOUT
            extendUnlock()
        end
        -- If we're no longer making wave in or wave out, stop shuttle behaviour.
        if edge == "off" then
            shuttleTimeout = nil
        end
    end
	
	-- Rotate
	if pose == "fist" then
		local now = myo.getTimeMilliseconds()
		
		if unlocked and edge == "on" then
			shuttleRotate = "Yes"
		
			myo.vibrate("short")
			objectRotate()
	
		elseif edge == "off" then
			myo.mouse("center", "up")
			myo.controlMouse(false)
			unlocked = false
		end
	end
	
	-- Pan
	if pose == "fingersSpread" then
		local now = myo.getTimeMilliseconds()
		
		if unlocked and edge == "on" then
			shuttlePan = "Yes"
		
			myo.vibrate("short")
			objectPan()
	
		elseif edge == "off" then
			myo.keyboard("left_control","up")
			myo.mouse("center", "up")
			myo.controlMouse(false)
			unlocked = false
		end
	end
end
	
-- All timeouts in milliseconds.

-- Time since last activity before we lock
UNLOCKED_TIMEOUT = 1000

-- Delay when holding wave left/right before switching to shuttle behaviour
SHUTTLE_CONTINUOUS_TIMEOUT = 100

-- How often to trigger shuttle behaviour
SHUTTLE_CONTINUOUS_PERIOD = 100

function onPeriodic()
    local now = myo.getTimeMilliseconds()

    -- Shuttle behaviour
    if shuttleTimeout then
        extendUnlock()

        -- If we haven't done a shuttle burst since the timeout, do one now
        if (now - shuttleSince) > shuttleTimeout then
            --  Perform a shuttle burst
            shuttleBurst()

            -- Update the timeout. (The first time it will be the longer delay.)
            shuttleTimeout = SHUTTLE_CONTINUOUS_PERIOD

            -- Update when we did the last shuttle burst
            shuttleSince = now
        end
    end

    -- Lock after inactivity
    if unlocked then
        -- If we've been unlocked longer than the timeout period, lock.
        -- Activity will update unlockedSince, see extendUnlock() above.
        if myo.getTimeMilliseconds() - unlockedSince > UNLOCKED_TIMEOUT then
            unlocked = false
        end
    end
end
	
	
function onForegroundWindowChange(app, title)
	-- Here we decide if we want to control the new active app
	local wantActive = false
	activeApp = ""
	
	wantActive = string.match(title, "^SolidWorks.*")
	activeApp = "SolidWorks"
		
	return wantActive
end

function activeAppName()
	-- Return the active app name determined in onForegroundWindowChange
	return activeApp
end

function onActiveChange(isActive)
	if not isActive then
		unlocked = false
	end
end

	
