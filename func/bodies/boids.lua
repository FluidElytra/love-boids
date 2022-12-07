Boids = Object:extend()


function Boids:new(x,y,vx,vy,radius,density,index)
	self.index = index
	self.position = Vector(x,y)
	self.velocity = Vector(vx,vy)

	self.radius = radius
	self.density = density
	self.h = 20
	self.w = 10
	self.theta = 0
	self.r_interactions = 100 -- separation radius
	self.neighbours = {} -- index of the neighbours

	self.separationTrig = true -- interaction states
	self.alignmentTrig = true -- interaction states
	self.cohesionTrig = true -- interaction states

	self.body = love.physics.newBody(world, x, y, 'dynamic')
   	self.shape = love.physics.newCircleShape(radius)
	self.fixture = love.physics.newFixture(self.body, self.shape, self.density)

	self.fixture:setUserData("boid_" .. index)
	
	if vx ~= 0 or vy ~= 0 then
		self.body:setLinearVelocity(self.velocity.x, self.velocity.y)
	end

end


function Boids:draw(boidList)
	self:drawBoid()
	self:drawNearest(boidList, self.neighbours)

	love.graphics.print("Rule 1 - separation : " .. (self.separationTrig and 'true' or 'false'), 20, 20)
	love.graphics.print("Rule 2 - alignment : " .. (self.alignmentTrig and 'true' or 'false'), 20, 40)
	love.graphics.print("Rule 3 - cohesion : " .. (self.cohesionTrig and 'true' or 'false'), 20, 60)

	if devMode == true then
		love.graphics.print("boid " .. self.index, math.ceil(self.position.x-self.radius*0.5), math.ceil(self.y-self.radius*0.5))
		love.graphics.print("X (" .. math.ceil(self.position.x) .. " ; " .. math.ceil(self.position.y) .. ")", math.ceil(self.position.x-self.radius*0.5), math.ceil(self.y-self.radius*0.5)+15)
		love.graphics.print("V (" .. math.ceil(self.velocity.x) .. " ; " .. math.ceil(self.velocity.y) .. ")", math.ceil(self.position.x-self.radius*0.5), math.ceil(self.y-self.radius*0.5)+30)
	end
end


function Boids:update(boidList)
	local vx, vy = self.body:getLinearVelocity()
	self.velocity = Vector(vx,vy)
	self.position = Vector(self.body:getX(),self.body:getY())

	self:interaction() -- let the player change the rules enabled in the simulation in real time

	self.neighbours = self:findNeighbours(boidList)

	if #self.neighbours > 0 then -- and (v_sep:len() > 0 or v_ali:len() > 0 or v_coh:len() > 0) then
		local v_sep = self:separation(boidList, self.neighbours) -- rule number 1
		local v_ali = self:alignment(boidList, self.neighbours) -- rule number 2
		local v_coh = self:cohesion(boidList, self.neighbours) -- rule number 3
		local vnew = Vector(0, 0)
		vnew = 0.1*self.velocity + 2*v_sep + v_ali + v_coh
		vnew = vnew:normalized() -- norme la direction générale
		vnew = vnew*velocity -- intensité constante de la vitesse
		self.body:setLinearVelocity(vnew.x, vnew.y)
	end

	self:angle() -- compute theta
	self:boundary() -- periodic boundary condition
end


function Boids:boundary()
	if self.position.x > wind_w then
		self.body:setPosition(0, self.position.y)
	elseif self.position.x < 0 then
		self.body:setPosition(wind_w, self.position.y)
	elseif self.position.y > wind_h then
		self.body:setPosition(self.position.x, 0)
	elseif self.position.y < 0 then
		self.body:setPosition(self.position.x, wind_h)
	end
end

-- RULE 1 - SEPARATION
function Boids:separation(boidList, neighbours)
	local c = 0 -- neighbor counter
	local dir = {} -- direction vector to escape neighbors
	local meandir = Vector(0,0) -- mean velocity direction to avoid all the neighbors
	
	if self.separationTrig == true then 
		for i = 0,#neighbours do
			dir[c] = Vector(self.position.x-boidList[neighbours[i]].position.x, self.position.y-boidList[neighbours[i]].position.y)
			dir[c] = dir[c]:normalized()
			dir[c] = dir[c]*math.exp(-0.5*(r/self.r_interactions)^2)
			meandir = meandir + dir[c]
			c = c + 1
		end

		if c ~= 0 and meandir:len() > 0 then
			meandir = meandir/c
		end
	end

	return meandir
end


-- RULE 2 - ALIGNMENT
function Boids:alignment(boidList, neighbours)
	local c = 0 -- neighbor counter
	local dir = {} -- direction vector to escape neighbors
	local meandir = Vector(0,0) -- mean velocity direction to avoid all the neighbors

	if self.alignmentTrig == true then
		for i = 0,#neighbours do
			dir[c] = Vector(boidList[neighbours[i]].velocity.x, boidList[neighbours[i]].velocity.y)
			dir[c] = dir[c]:normalized()
			meandir = meandir + dir[c]
			c = c + 1
		end
		if c ~= 0 and meandir:len() > 0 then
			meandir = meandir/c
		end
	end

	return meandir
end


-- RULE 3 - COHESION
function Boids:cohesion(boidList,neighbours)
	local dir = Vector(0,0)
	local c = 0 -- neighbor counter
	local bar = Vector(0,0) -- mean velocity direction to avoid all the neighbors

	if self.cohesionTrig == true then
		for i = 0,#neighbours do
			bar = bar + boidList[neighbours[i]].position
			c = c + 1
		end
		if c ~= 0 and bar:len() > 0 then
			bar = bar/c
			dir = bar - self.position
			dir = dir:normalized()
		end
	end

	return dir
end


function Boids:findNeighbours(boidList)
	local c = 0
	local neighbours = {}
	for i = 1,#boidList do
		local r = math.sqrt((self.position.x-boidList[i].position.x)^2+(self.position.y-boidList[i].position.y)^2)
		if r < self.r_interactions then
			neighbours[c] = i
			c = c + 1
		end
	end
	return neighbours
end


-- RENDERING & INTERACTIONS
function Boids:angle()
	if self.velocity.x > 0 and self.velocity.y >= 0 then
		self.theta = -math.atan(self.velocity.x/self.velocity.y)
	elseif self.velocity.x < 0 and self.velocity.y >= 0 then
		self.theta = -math.atan(self.velocity.x/self.velocity.y)
	elseif self.velocity.x <= 0 and self.velocity.y < 0 then
		self.theta = -math.atan(self.velocity.x/self.velocity.y)-math.pi
	elseif self.velocity.x > 0 and self.velocity.y < 0 then
		self.theta = -math.atan(self.velocity.x/self.velocity.y)-math.pi
	end
end


function Boids:drawBoid()
	if self.index == 1 then
		love.graphics.setColor( 30/255, 30/255, 30/255)
		love.graphics.circle('fill', self.position.x, self.position.y, self.r_interactions)-- plot
		love.graphics.setColor( 50/255, 50/255, 50/255)
		love.graphics.circle('fill', self.position.x, self.position.y, self.r_interactions)-- plot
		love.graphics.setColor(217/255, 91/255, 122/255)
	else
		love.graphics.setColor(1, 1, 1)
	end
	local x1, y1 = self.position.x            , self.position.y+0.5*self.h
	local x2, y2 = self.position.x+0.5*self.w , self.position.y-0.5*self.h
	local x3, y3 = self.position.x-0.5*self.w , self.position.y-0.5*self.h
	love.graphics.push()
	love.graphics.translate(self.position.x, self.position.y)
	love.graphics.rotate(self.theta)
	love.graphics.translate(-self.position.x, -self.position.y)
	love.graphics.polygon('fill', x1, y1, x2, y2, x3, y3)-- plot
	love.graphics.pop()
	love.graphics.origin()
end


function Boids:drawNearest(boidList, neighbours)
	if self.index == 1 then
		for i = 1, #neighbours do
			love.graphics.line(self.position.x, self.position.y, boidList[neighbours[i]].position.x, boidList[neighbours[i]].position.y)
		end

	end
end


function Boids:interaction()
	-- Enable or disable boids rules
	if love.keyboard.isDown("kp1") then
		if self.separationTrig == true then
			Timer.after(0.3, 
				function()
					self.separationTrig = false
				end)
		else
			Timer.after(0.3, 
				function()
					self.separationTrig = true
				end)
		end
	elseif love.keyboard.isDown("kp2") then
		if self.alignmentTrig == true then
			Timer.after(0.3, 
				function()
					self.alignmentTrig = false
				end)
		else
			Timer.after(0.3, 
				function()
					self.alignmentTrig = true
				end)
		end
	elseif love.keyboard.isDown("kp3") then
		if self.cohesionTrig == true then
			Timer.after(0.3, 
				function()
					self.cohesionTrig = false
				end)
		else
			Timer.after(0.3, 
				function()
					self.cohesionTrig = true
				end)
		end
	end
end

