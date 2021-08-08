-- https://github.com/Ulydev/push
push = require 'push'
-- https://github.com/vrld/hump/blob/master/class.lua
Class = require 'class'
require 'Paddle'
require 'Ball'
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243
PADDLE_SPEED = 200
player2hits=0
counterhits=0
consechits=0
function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.window.setTitle('Pong')
    math.randomseed(os.time())
    smallFont = love.graphics.newFont('font.ttf', 8)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    love.graphics.setFont(smallFont)
    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static'),
        ['bonus1'] = love.audio.newSource('sounds/bonus1.wav', 'static'),
        ['bonus2'] = love.audio.newSource('sounds/bonus2.wav', 'static')
    }
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true,
        canvas = false
    })
    player1 = Ball(10, VIRTUAL_HEIGHT / 2 - 2, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)
    player1Score = 0
    player2Score = 0
    servingPlayer = 1
    winningPlayer = 0
    gameState = 'start'
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.update(dt)
    if gameState == 'serve' then
        -- before switching to play, initialize ball's velocity based
        -- on player who last scored
        ball.dy = math.random(-50, 50)
        player1.dy=ball.dy
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
    elseif gameState == 'play' then
        -- detect ball collision with paddles, reversing dx if true and
        -- slightly increasing it, then altering the dy based on the position
        -- at which it collided, then playing a sound effect
        if ball:collides(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + 5

            -- keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
                player1.dy=ball.dy
            else
                ball.dy = math.random(10, 150)
                player1.dy=ball.dy
            end

            sounds['paddle_hit']:play()
        end
        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4
            counterhits=player2hits+1
            player2hits=counterhits
            consechits=consechits+1
            -- keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
                player1.dy=ball.dy
            else
                ball.dy = math.random(10, 150)
                player1.dy=ball.dy
            end

            sounds['paddle_hit']:play()
        end

        if player2hits==4 then
        	player2Score = player2Score + 1
            sounds['bonus1']:play()
            --sounds['score']:play()
            player2hits=0
            counterhits=0
            -- if we've reached a score of 10, the game is over; set the
            -- state to done so we can show the victory message
            if player2Score >= 12 then
                winningPlayer = 2
                gameState = 'done'
            elseif player2Score - player1Score >=0 then
                sounds['paddle_hit']:play()
                sounds['score']:play()
                a=player2Score - player1Score
                add=a * a
                add=add + 1
                player2Score = player2Score + add
                if player2Score >= 12 then
                    winningPlayer = 2
                    gameState = 'done'
                    ball:reset()
                    player1=Ball(10, VIRTUAL_HEIGHT / 2 - 2, 5, 20)
                else
                    gameState='serve'
                    -- places the ball in the middle of the screen, no velocity
                    ball:reset()
                    player1=Ball(10, VIRTUAL_HEIGHT / 2 - 2, 5, 20)
                end
                --love.graphics.setFont(smallFont)
                --love.graphics.printf('BONUS', 0, 10, VIRTUAL_WIDTH, 'center')
            else
                gameState = 'serve'
                -- places the ball in the middle of the screen, no velocity
                ball:reset()
                player1=Ball(10, VIRTUAL_HEIGHT / 2 - 2, 5, 20)
            end
        end
        -- detect upper and lower screen boundary collision, playing a sound
        -- effect and reversing dy if true
        if ball.y <= 0 then
            ball.y = 0
            player1.y=ball.y
            ball.dy = -ball.dy
            player1.dy=ball.dy
            sounds['wall_hit']:play()
        end

        -- -4 to account for the ball's size
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            player1.y=ball.y
            ball.dy = -ball.dy
            player1.dy=ball.dy
            sounds['wall_hit']:play()
        end

        -- if we reach the left or right edge of the screen, go back to serve
        -- and update the score and serving player
        if ball.x < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            consechits=0
            sounds['score']:play()
            player2hits=0
            counterhits=0
            -- if we've reached a score of 10, the game is over; set the
            -- state to done so we can show the victory message
            if player2Score == 12 then
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                -- places the ball in the middle of the screen, no velocity
                ball:reset()
                player1=Ball(10, VIRTUAL_HEIGHT / 2 - 2, 5, 20)
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()
            player2hits=0
            counterhits=0
            if player1Score == 12 then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
                player1=Ball(10, VIRTUAL_HEIGHT / 2 - 2, 5, 20)
            end
        end
    end

    --
    -- paddles can move no matter what state we're in
    --
    -- player 1
    --if love.keyboard.isDown('w') then
    --    player1.dy = -PADDLE_SPEED
    --elseif love.keyboard.isDown('s') then
    --    player1.dy = PADDLE_SPEED
    --else
    --    player1.dy = 0
    --end

    -- player 2
    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    -- update our ball based on its DX and DY only if we're in play state;
    -- scale the velocity by dt so movement is framerate-independent
    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)
end

--[[
    A callback that processes key strokes as they happen, just the once.
    Does not account for keys that are held down, which is handled by a
    separate function (`love.keyboard.isDown`). Useful for when we want
    things to happen right away, just once, like when we want to quit.
]]
function love.keypressed(key)
    -- `key` will be whatever key this callback detected as pressed
    if key == 'escape' then
        -- the function LÖVE2D uses to quit the application
        love.event.quit()
    -- if we press enter during either the start or serve phase, it should
    -- transition to the next appropriate state
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            -- game is simply in a restart phase here, but will set the serving
            -- player to the opponent of whomever won for fairness!
            gameState = 'serve'

            ball:reset()
            player1=Ball(10, VIRTUAL_HEIGHT / 2 - 2, 5, 20)
            -- reset scores to 0
            player1Score = 0
            player2Score = 0

            -- decide serving player as the opposite of who won
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
end

--[[
    Called each frame after update; is responsible simply for
    drawing all of our game objects and more to the screen.
]]
function love.draw()
    -- begin drawing with push, in our virtual resolution
    push:start()

    love.graphics.clear(40, 45, 52, 255)
    
    -- render different things depending on which part of the game we're in
    if gameState == 'start' then
        -- UI messages
        love.graphics.setFont(smallFont)
        love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to begin!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        -- UI messages
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        -- no UI messages to display in play
    elseif gameState == 'done' then
        -- UI messages
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!',
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
    end

    -- show the score before ball is rendered so it can move over the text
    displayScore()
    
    player1:render()
    player2:render()
    if ball.x<=100 or ball.x>=200 or player2Score>=player1Score+2 then
        ball:render()
    end

    -- display FPS for debugging; simply comment out to remove
    displayFPS()

    -- end our drawing to push
    push:finish()
end

--[[
    Simple function for rendering the scores.
]]
function displayScore()
    -- score display
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50,
        VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30,
        VIRTUAL_HEIGHT / 3)
end

--[[
    Renders the current FPS.
]]
function displayFPS()
    -- simple FPS display across all states
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
    love.graphics.setColor(255, 255, 255, 255)
end
