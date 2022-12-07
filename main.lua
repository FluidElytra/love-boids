function love.load()
	Object = require "lib/classic"
	Camera = require "lib/hump.camera"
	Timer = require "lib/hump.timer"
	Vector = require "lib/hump.vector"
	require "func/bodies/boids"
	C_d				 = 16*4													-- [px/m] Coefficient de conversion
	L_x				 = love.graphics.getWidth()     						-- [px] Largeur de la fenêtre de jeu
	L_x_lim			 = 600
	L_y				 = love.graphics.getHeight()    						-- [px] Hauteur de la fenêtre de jeu
	rho 			 = 2*1/C_d^2												-- [kg/px2] Densité massique
	dt 				 = 1													-- [s] Pas de temps entre deux itérations
	devMode			 = false												-- Enable or disable the dev mode
	text_coll  		 = ""   												-- Variable pour détecter collision (dev mode)
	love.physics.setMeter(C_d)												-- One meter equals to C_d pixels
	world = love.physics.newWorld(0, 0, false)								-- The physics world
	love.graphics.setDefaultFilter('nearest','nearest') 					-- Pas de filtre pour les sprites
	timer = Timer.new()
	love.graphics.setBackgroundColor( 31/255, 36/255, 48/255)
	wind_w = 1800
	wind_h = 1000
	love.window.setMode(wind_w, wind_h)
	
	r = 0.5 -- boids radius
	velocity = 100 -- boids velocity
	N_boids = 100 -- boids number
	boids = {} -- boids table

	math.randomseed(os.time()) -- seed
	for i=1,N_boids do -- initialize boids position and motion direction
		local x = math.random(1, wind_w)
		local y = math.random(1, wind_h)
		local dirx = math.random(-10,10)
		local diry = math.random(-10,10)
		local magnv = math.sqrt(dirx^2+diry^2)
		local vx = velocity*dirx/magnv
		local vy = velocity*diry/magnv
		boids[i] = Boids(x,y,vx,vy,r,rho,i)
	end
end

function love.update(dt)
	world:update(dt)
	Timer.update(dt)
	for i = 1,#boids do
		boids[i]:update(boids)
	end
end

function love.draw()
	for i = 1,#boids do
		boids[i]:draw(boids)
	end
end

function beginContact(fixture1, fixture2, coll)
    -- text_coll = text_coll.."\n"..fixture1:getUserData().." colliding with "..fixture2:getUserData()
end
 
function endContact(fixture1, fixture2, coll)
    -- text_coll = text_coll.."\n"..fixture1:getUserData().." uncolliding with "..fixture2:getUserData()
end
 
function preSolve(fixture1, fixture2, coll)
end
 
function postSolve(fixture1, fixture2, coll, normalimpulse, tangentimpulse)
end