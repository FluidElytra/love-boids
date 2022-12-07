Plateform = Object:extend()

function Plateform:new(x,y,width,height,density,index)
	-- x et y correspondent au CENTRE DE MASSE
	self.colorR = 255
	self.colorG = 255
	self.colorB = 255
	self.index = index

	self.x = x
	self.y = y
	self.width = width
	self.height = height

	self.body = love.physics.newBody(world, x, y, 'static')
	self.shape = love.physics.newRectangleShape(width, height)
	self.fixture = love.physics.newFixture(self.body, self.shape, density)
	self.fixture:setUserData("Plateform_" .. index)
end

function Plateform:draw()
	love.graphics.setColor(self.colorR,self.colorG,self.colorB)
	love.graphics.rectangle("line", self.x - math.ceil(self.width*0.5), self.y -  math.ceil(self.height*0.5), self.width, self.height)
	if devMode == true then
		love.graphics.print("plateform " .. self.index, math.ceil(self.x-self.width*0.5), math.ceil(self.y-self.height*0.5))
  		love.graphics.print("(" .. math.ceil(self.x) .. " ; " .. math.ceil(self.y) .. ")", math.ceil(self.x-self.width*0.5), math.ceil(self.y-self.height*0.5)+15)
	end
end

function Plateform:update()
	self.x = self.body:getX()
	self.y = self.body:getY()
end