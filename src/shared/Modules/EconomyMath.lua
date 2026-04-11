local EconomyMath = {}

EconomyMath.POWER_BASE_PRICE = 100
EconomyMath.POWER_MULTIPLIER = 1.15
EconomyMath.MINE_BASE_PRICE = 100
EconomyMath.MINE_MULTIPLIER = 1.3
EconomyMath.SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No" }

function EconomyMath.GetSingleLevelCost(basePrice, multiplier, currentLevel)
	return math.floor(basePrice * math.pow(multiplier, currentLevel))
end

function EconomyMath.GetCumulativeUpgradeCost(basePrice, multiplier, currentLevel, levelsToAdd)
	local totalCost = 0

	for i = 0, levelsToAdd - 1 do
		local costForThisLevel = EconomyMath.GetSingleLevelCost(basePrice, multiplier, currentLevel + i)
		totalCost += costForThisLevel
	end

	return totalCost
end

function EconomyMath.GetPowerUpgradeCost(currentLevel, levelsToAdd)
	return EconomyMath.GetCumulativeUpgradeCost(
		EconomyMath.POWER_BASE_PRICE,
		EconomyMath.POWER_MULTIPLIER,
		currentLevel,
		levelsToAdd
	)
end

function EconomyMath.GetMineUpgradeCost(currentLevel, levelsToAdd)
	return EconomyMath.GetCumulativeUpgradeCost(
		EconomyMath.MINE_BASE_PRICE,
		EconomyMath.MINE_MULTIPLIER,
		currentLevel,
		levelsToAdd
	)
end

function EconomyMath.FormatNumber(n: number): string
	local absoluteValue = math.abs(n)
	if absoluteValue < 1000 then
		return tostring(math.floor(n))
	end

	local exp = math.floor(math.log10(absoluteValue) / 3)
	local suffixIndex = math.clamp(exp + 1, 1, #EconomyMath.SUFFIXES)
	local value = n / (10 ^ ((suffixIndex - 1) * 3))

	return string.format("%.1f%s", value, EconomyMath.SUFFIXES[suffixIndex]):gsub("%.0", "")
end

return EconomyMath
