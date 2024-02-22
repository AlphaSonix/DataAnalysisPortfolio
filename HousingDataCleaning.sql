SELECT * 
FROM PortfolioProject..Housing

--Standardise date format for SaleDate col

SELECT SaleDateConverted --, CONVERT(Date, SaleDate)
FROM PortfolioProject..Housing

ALTER TABLE Housing
ADD SaleDateConverted Date;

UPDATE Housing
SET SaleDateConverted = CONVERT (Date, SaleDate)

--Populate Missing Values for the PropertyAddress column

--checks if any property fields are null
SELECT *
FROM PortfolioProject..Housing
--WHERE PropertyAddress is null
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..Housing a
JOIN PortfolioProject..Housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..Housing a
JOIN PortfolioProject..Housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null


--Breaking data down into individual columns (PropertyAddress currently contains address and city)

SELECT PropertyAddress 
FROM PortfolioProject..Housing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))as City
FROM PortfolioProject..Housing

ALTER TABLE Housing
ADD Splice_Address varchar(255);

UPDATE Housing
SET Splice_Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE Housing
ADD Splice_City Nvarchar(255);

UPDATE Housing
SET Splice_City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


-- Parsing owner address (address, city, state)

SELECT OwnerAddress
FROM PortfolioProject..Housing

SELECT
PARSENAME(REPLACE(OwnerAddress,',','.') , 3),
PARSENAME(REPLACE(OwnerAddress,',','.') , 2),
PARSENAME(REPLACE(OwnerAddress,',','.') , 1)
FROM PortfolioProject..Housing

ALTER TABLE Housing
ADD Parse_OwnerAddress Nvarchar(255);

ALTER TABLE Housing
ADD Parse_OwnerCity Nvarchar(255);

ALTER TABLE Housing
ADD Parse_OwnerState Nvarchar(255);

UPDATE Housing
SET Parse_OwnerAddress = PARSENAME(REPLACE(OwnerAddress,',','.') , 3)

UPDATE Housing
SET Parse_OwnerCity = PARSENAME(REPLACE(OwnerAddress,',','.') , 2)

UPDATE Housing
SET Parse_OwnerState = PARSENAME(REPLACE(OwnerAddress,',','.') , 1)


-- Consistency Problem: Some fields in SoldAsVacant are 'Yes' or 'Y', 'No' or 'N'. Should be more uniformal.

-- checking the number of distinct fields 
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..Housing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM PortfolioProject..Housing

UPDATE Housing
SET SoldAsVacant =
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END


-- Removing Duplicates of data from the table

WITH RowNumCTE as(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
				 ) row_num
FROM PortfolioProject..Housing
--Order BY  ParcelID
)

--DELETE
--FROM RowNumCTE
--WHERE row_num > 1

SELECT * 
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress


-- Deleting Unused Columns

ALTER TABLE PortfolioProject..Housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
