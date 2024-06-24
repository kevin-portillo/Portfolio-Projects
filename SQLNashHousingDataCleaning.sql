/*

Cleaning data in SQL queries

*/

SELECT * FROM SQLNashHousingPortfolioProject.dbo.NashvilleHousing

--Standardize Date Format
SELECT SaleDate, CONVERT(date, SaleDate)
FROM SQLNashHousingPortfolioProject..NashvilleHousing

/* Following was supposed to change the SaleDate value formata but it wasnt working

UPDATE SQLNashHousingPortfolioProject..NashvilleHousing
SET SaleDate=CONVERT(Date, SaleDate)

SELECT SaleDate FROM SQLNashHousingPortfolioProject.dbo.NashvilleHousing
*/

--So this had to be done to workaround it(add a column, add converted date to new col):
ALTER TABLE SQLNashHousingPortfolioProject..NashvilleHousing
ADD SaleDateConverted DATE;

UPDATE SQLNashHousingPortfolioProject..NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

SELECT * FROM SQLNashHousingPortfolioProject..NashvilleHousing


--Populate Property Address data(Some PropertyAddress values are NULL. If ParcelIDs are the same then address must be the same)

SELECT *
FROM SQLNashHousingPortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress is null
ORDER BY ParcelID

	--self join on parcel ids that are the same but only if unique ids are different, ISNULL(expression, value)[returns expression 
	--if not null, otherwise returns value] Just a table join to see any results
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM SQLNashHousingPortfolioProject..NashvilleHousing a
JOIN SQLNashHousingPortfolioProject..NashvilleHousing b
ON a.ParcelID=b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]

	--Update the table using filter from above query. If address is NULL, it will fill in the property address with the address of 
	-- a parcel with the same ID but a different unique ID
UPDATE a
SET PropertyAddress=ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM SQLNashHousingPortfolioProject..NashvilleHousing a
JOIN SQLNashHousingPortfolioProject..NashvilleHousing b
ON a.ParcelID=b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

--Splitting address into individual cols(Address, City, State)

	--Part 1: Split property address

	--SUBSTRING(string to extract from, start position, length num of chars to extract)
	--CHARINDEX(substring to search for, string to be searched) -returns position of match
	--In AS Address, we do Charindex(..)-1 to not include the ",". if it was just charindex(..), Address would include the ","
	--In AS City, we do Charindex(..)+1 to not include ",". if it was just charindex(..), Address would include the ","
SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM SQLNashHousingPortfolioProject..NashvilleHousing

	--Adding new col for split address and updating
ALTER TABLE SQLNashHousingPortfolioProject..NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE SQLNashHousingPortfolioProject..NashvilleHousing
SET PropertySplitAddress=SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)

	--Add new col for city part from split address and updating
ALTER TABLE SQLNashHousingPortfolioProject..NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE SQLNashHousingPortfolioProject..NashvilleHousing
SET PropertySplitCity=SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))



	--Part 2: Split owner address
	--PARSENAME(object/string, object_piece/part) : splits the object/string on a '.' For some reason, parts are read from 
	--right to left. EX 'abc.def.ghi', part 1 is 'ghi', part 2 is 'def', and part 3 is 'abc'
	--REPLACE(string, string to be replaced, new replacement string)
		-- we are changing the commas in OwnerAddress to periods, so PARSENAME can be used

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.' ),3) AS OwnerAddress,
PARSENAME(REPLACE(OwnerAddress,',','.' ),2) AS City,
PARSENAME(REPLACE(OwnerAddress,',','.' ),1) AS State
FROM SQLNashHousingPortfolioProject..NashvilleHousing

	--Add new col for address part from split owner address and update
ALTER TABLE SQLNashHousingPortfolioProject..NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

UPDATE SQLNashHousingPortfolioProject..NashvilleHousing
SET OwnerSplitAddress=PARSENAME(REPLACE(OwnerAddress,',','.' ),3)

	--Add new col for city part from split owner address and update
ALTER TABLE SQLNashHousingPortfolioProject..NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

UPDATE SQLNashHousingPortfolioProject..NashvilleHousing
SET OwnerSplitCity=PARSENAME(REPLACE(OwnerAddress,',','.' ),2)

	--Add new col for state part from split owner address and update
ALTER TABLE SQLNashHousingPortfolioProject..NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE SQLNashHousingPortfolioProject..NashvilleHousing
SET OwnerSplitState=PARSENAME(REPLACE(OwnerAddress,',','.' ),1)

--SELECT * FROM SQLNashHousingPortfolioProject..NashvilleHousing

--Change Y and N to Yes and No in "Sold as Vacant"
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM SQLNashHousingPortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

	--Check to see if case was successful and value was changed
SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM SQLNashHousingPortfolioProject.dbo.NashvilleHousing

	--Update table and change 'Y' to 'Yes' or 'N' to 'No' or leave as is
UPDATE SQLNashHousingPortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END

--Remove duplicates
--creates a cte that has all the previous columns plus a col titled row_num. Partition on things that should be unique for
--each row. Ex, if ParcelID, propertyaddress, saleprice,saledate, and legalreference are all the same between two or more rows
--then we assume it is the same data(duplicate)
WITH RowNumCTE AS(
SELECT *, ROW_NUMBER() OVER (
PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
ORDER BY UniqueID) row_num
FROM SQLNashHousingPortfolioProject..NashvilleHousing)

SELECT * FROM RowNumCTE
WHERE row_num>1
--ORDER BY PropertyAddress

/* used following command to delete duplicates, then did 'SELECT * FROM RowNumCTE
WHERE row_num>1' to see if all duplicates were deleted

DELETE 
FROM RowNumCTE
WHERE row_num>1
*/

--Delete unused columns
ALTER TABLE SQLNashHousingPortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE SQLNashHousingPortfolioProject..NashvilleHousing
DROP COLUMN SaleDate

SELECT * FROM SQLNashHousingPortfolioProject..NashvilleHousing
