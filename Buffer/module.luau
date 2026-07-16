const EncodingService = game:GetService("EncodingService")
const HttpService = game:GetService("HttpService")

const recursiveSmallCall = function(callback, ...)
	callback(callback, ...)
end

export type Buffer = {
	values: { [any]: { any } },
	compressionAlgorithm: Enum.CompressionAlgorithm,
	compressionLevel: number,

	ValueTypes: { [string]: number | (value: any) -> number },
	ValueClasses: { [string]: ValueClass },

	new: () -> Buffer,
	createValue: (self: Buffer, valueType: string, name: string | number?, parentName: string?) -> Buffer,
	setCompression: (self: Buffer, algorithm: Enum.CompressionAlgorithm?, level: number?) -> Buffer,
	processBuffer: (self: Buffer, buff: buffer) -> buffer,
	read: (self: Buffer, buff: buffer, name: string | number) -> any,
	toTable: (self: Buffer, buff: buffer) -> { [any]: any },
	build: (self: Buffer, values: { [string]: any }) -> buffer,
}

export type ValueClass = {
	name: string,
	types: { string },
	serial: (...any) -> { any },
	deserial: (...any) -> any,
}

const public: Buffer = {}
public.__index = public

public.ValueTypes = {
	i8 = 1,
	i16 = 2,
	i32 = 4,
	u8 = 1,
	u16 = 2,
	u32 = 4,
	f32 = 4,
	f64 = 8,
	bool8 = 1,
	string = function(str: string)
		return string.len(str)
	end,
}

--[[
	these classes have their sizes calculated dynamically when the buffer gets built to avoid collisions
	but only if the type contains a base type that can change dynamically sizes
]]
public.ValueClasses = {
	vector2 = {
		types = { "f64", "f64" },
		serial = function(vec: Vector2)
			return { vec.X, vec.Y }
		end,
		deserial = function(x: number, y: number)
			return Vector2.new(x, y)
		end,
	},
	vector3 = {
		types = { "f64", "f64", "f64" },
		serial = function(vec: Vector3)
			return { vec.X, vec.Y, vec.Z }
		end,
		deserial = function(x: number, y: number, z: number)
			return Vector3.new(x, y, z)
		end,
	},
	-- this class is approx. 0,0000001201370026 precise
	cframe = {
		types = { "vector3", "vector3" },
		serial = function(cfr: CFrame)
			return { { cfr.Position }, { Vector3.new(cfr:ToOrientation()) } }
		end,
		deserial = function(pos: Vector3, eulerVec: Vector3)
			return CFrame.new(pos.X, pos.Y, pos.Z) * CFrame.fromOrientation(eulerVec.X, eulerVec.Y, eulerVec.Z)
		end,
	},
	-- this class is exact but is double the size
	cframe_lossless = {
		types = { "f64", "f64", "f64", "f64", "f64", "f64", "f64", "f64", "f64", "f64", "f64", "f64" },
		serial = function(cfr: CFrame)
			return { cfr:GetComponents() }
		end,
		deserial = function(x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22)
			return CFrame.new(x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22)
		end,
	},
}

-- dont look at anything below this line

const function getBaseTypes(t: string, rootClass: string?, typeIndex: { number }?): { [number]: string }
	rootClass = rootClass or t
	typeIndex = typeIndex or { 0 }
	local typeSize = public.ValueTypes[t]
	local classData = public.ValueClasses[t]

	if typeSize then
		typeIndex[1] += 1
		return true
	end

	if classData then
		local types = {}
		for _, nt in pairs(classData.types) do
			local result = getBaseTypes(nt, rootClass, typeIndex)
			if result == true then
				types[typeIndex[1]] = nt
			else
				for i, rt in pairs(result) do
					types[i] = rt
				end
			end
		end
		return types
	end
end

-- solve class sizes if possible else solve them dynamically on buffer build
const function solveClassSize(
	t: string,
	solvedTypeSizes: { [number]: number }?,
	rootClass: string?,
	unsolvedIndex: { number }?
)
	rootClass = rootClass or t
	unsolvedIndex = unsolvedIndex or { 0 }
	local typeSize = public.ValueTypes[t]
	local classData = public.ValueClasses[t]

	if typeSize then
		if type(typeSize) == "number" then
			return true, typeSize
		else
			unsolvedIndex[1] += 1

			local uIndex = unsolvedIndex[1]
			if solvedTypeSizes and solvedTypeSizes[uIndex] then
				return true, solvedTypeSizes[uIndex]
			end

			local rootData = public.ValueClasses[rootClass]
			if rootData then
				if not rootData.unsolvableIndex then
					rootData.unsolvableIndex = {}
				end
				if not solvedTypeSizes and not table.find(rootData.unsolvableIndex, uIndex) then
					table.insert(rootData.unsolvableIndex, uIndex)
				end

				rootData.hasUnsolvableType = true
			end

			warn(
				"[Buffer] could not solve '"
					.. t
					.. "' at ("
					.. tostring(uIndex)
					.. ") ["
					.. rootClass
					.. "]; did you forget to supply a value?; ",
				solvedTypeSizes
			)
			return false
		end
	end

	local gsize = 0
	if classData then
		if not solvedTypeSizes and classData.size then
			return true, classData.size
		end

		local failed = false
		for _, nt in pairs(classData.types) do
			local success, size = solveClassSize(nt, solvedTypeSizes, rootClass, unsolvedIndex)
			if success then
				gsize += size
			else
				failed = true
			end
		end
		if failed then
			return false
		end
		classData.size = gsize
	end
	return true, gsize
end

for c, d in pairs(public.ValueClasses) do
	local success, size = solveClassSize(c)
	print("class", c, "solved", success, "size", size, "unsolvedIndex", d.unsolvableIndex)
	d.name = c
end

function public.new(): Buffer
	return setmetatable({
		values = {},
	}, public) :: any
end

--[[
	creates a value object in this buffer using a value type (module.ValueTypeSizes)
	with a additional name (defaults to a counting index)
]]
function public.createValue(
	self: Buffer,
	valueType: string | ValueClass,
	name: string | number?,
	parentName: string?,
	super
): Buffer
	local v = {
		type = valueType,
		name = name or #self.values + 1,
		size = 0,
		parent = parentName,
	}
	table.insert(self.values, v)

	if valueType == "bool8" then
		v.value = {}
	end

	local class = public.ValueClasses[valueType] or valueType
	if class and type(class) == "table" then
		local childTypes = {}
		local superClass = v
		local baseTypes = superClass.baseTypes or getBaseTypes(valueType)

		v.baseTypes = baseTypes
		v.childTypes = childTypes
		v.class = class
		v.superClass = super or v

		for i, t in pairs(class.types) do
			local name = HttpService:GenerateGUID(false)
			local _, ntv = self:createValue(t, name, parentName, superClass)
			ntv.classIndex = table.find(baseTypes, t)
			if ntv.classIndex then
				baseTypes[ntv.classIndex] = ">.<"
			end
			ntv.superClassTypes = baseTypes
			ntv.superClass = superClass
			childTypes[i] = ntv
		end

		v.typeIndex = nil
		v.baseTypes = nil
	end

	return self, v
end

function public._setValue(self: Buffer, name: string, value: any): Buffer
	return self:_setValues({ [name] = value })
end

function public._setValues(self: Buffer, values: { [string]: any }): Buffer
	for _, v in pairs(self.values) do
		local value = values[v.name]
		if value then
			if v.class then
				value = v.class.serial(table.unpack(value))
				v.value = value
				local nnvs = {}
				local ci = 1
				for i, nv in pairs(v.childTypes) do
					local name = nv.name
					local nvs = value[ci]
					nnvs[name] = nvs
					ci += 1
				end
				self:_setValues(nnvs)
			else
				v.size = public.ValueTypes[v.type]

				if v.type == "bool8" then
					for i, cv in pairs(value) do
						if i <= v.size * 8 then
							v.value[i] = if cv then 1 else 0
						end
					end
				else
					v.value = value
				end
			end

			local valueTypeSize = v.size
			if type(valueTypeSize) == "function" then
				v.size = valueTypeSize(value)
			end
		end
	end
	return self
end

function public.setCompression(self: Buffer, algorithm: Enum.CompressionAlgorithm?, level: number?): Buffer
	self.compressionAlgorithm, self.compressionLevel = algorithm, level
	return self
end

function public.processBuffer(self: Buffer, buff: buffer): buffer
	if self.compressionAlgorithm then
		buff = EncodingService:CompressBuffer(buff, self.compressionAlgorithm, self.compressionLevel)
	end

	return buff
end

function public._getValue(self: Buffer, name: string | number): any
	for _, v in pairs(self.values) do
		if v.name == name then
			return v
		end
	end
end

function classRead(self: Buffer, buff: buffer, v): number
	local typeSize = public.ValueTypes[v.type]
	if typeSize then
		return self:read(buff, v.name)
	elseif v.class then
		local read = {}
		for _, nv in pairs(v.childTypes) do
			table.insert(read, classRead(self, buff, nv))
		end
		return v.class.deserial(table.unpack(read))
	end
end

function public.read(self: Buffer, buff: buffer, name: string | number): any
	local gsize = 0
	local v = self.values[name]
	for _, v in pairs(self.values) do
		if v.name == name then
			if v.class then
				return classRead(self, buff, v)
			elseif v.type == "string" then
				return buffer["read" .. v.type](buff, gsize, v.size)
			elseif v.type == "bool8" then
				local bits = {}
				for i = 1, v.size * 8 do
					bits[i] = buffer.readbits(buff, (gsize * 8) + i - 1, 1) == 1
				end
				return bits
			else
				return buffer["read" .. v.type](buff, gsize)
			end
		end
		gsize += v.size
	end
	return nil
end

const function solveValueSizes(self: Buffer, v)
	local t = v.type
	local typeSize = public.ValueTypes[t]
	local classData = v.class

	if typeSize then
		if typeof(typeSize) == "function" then
			return typeSize(self:_getValue(v.name).value)
		end
		return typeSize
	end

	if classData then
		local solvedSizes = {}
		for _, nv in pairs(v.childTypes) do
			if nv.class then
				continue
			end
			local size = solveValueSizes(self, nv)
			solvedSizes[nv.classIndex] = size
		end
		return solveClassSize(v.type, solvedSizes)
	end
end

function public.build(self: Buffer, values: { [string]: any }): buffer
	if values then
		self:_setValues(values)
	end

	local size = 0
	for _, v in pairs(self.values) do
		if v.class then
			if v.class.hasUnsolvableType then
				print(solveValueSizes(self, v))
			end
			size += v.class.size
		else
			size += v.size
		end
	end

	local buff = buffer.create(size)
	local gsize = 0
	for _, v in pairs(self.values) do
		if v.class then
			continue
		end
		if v.type == "bool8" then
			for i, bit in pairs(v.value) do
				buffer.writebits(buff, (gsize * 8) + i - 1, 1, bit)
			end
		else
			buffer["write" .. v.type](buff, gsize, v.value)
		end
		gsize += v.size
	end

	if self.compressionAlgorithm then
		return EncodingService:CompressBuffer(buff, self.compressionAlgorithm, self.compressionLevel)
	end

	return buff
end

return public
