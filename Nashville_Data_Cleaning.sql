# Cleaning Nashville Housing data usinq SQL Queries


SELECT * FROM DataProjects.nashville_data;

-- Standardize Date and convert it to 'Date' Datatype 

UPDATE DataProjects.nashville_data
SET SaleDate = STR_TO_DATE(SaleDate, '%M %d, %Y');

-- If the above query does not update properly 
SELECT SaleDate, STR_TO_DATE(SaleDate, '%M %d, %Y') FROM DataProjects.nashville_data;

ALTER TABLE DataProjects.nashville_data ADD SaleDateConverted DATE;

UPDATE DataProjects.nashville_data
SET SaleDateConverted = STR_TO_DATE(SaleDate, '%M %d, %Y');


-- Populate Missing Property Address data
-- Filling in the Property Address by looking at the address from the previous records with the same ParcelID 

SELECT * FROM DataProjects.nashville_data WHERE PropertyAddress = '' ORDER BY ParcelID;

-- Looking at the Property Addresses of the  previous records with the same ParcelID

SELECT * FROM DataProjects.nashville_data 
WHERE ParcelID IN (SELECT ParcelID FROM DataProjects.nashville_data WHERE PropertyAddress = '');

SELECT t1.ParcelID, t1.PropertyAddress, t2.ParcelID, t2.PropertyAddress, COALESCE(NULLIF(t1.PropertyAddress,''),t2.PropertyAddress)
FROM DataProjects.nashville_data t1
INNER JOIN DataProjects.nashville_data t2
ON t1.ParcelID  = t2.ParcelID
AND t1.UniqueID <> t2.UniqueID
WHERE t1.PropertyAddress = '';

UPDATE DataProjects.nashville_data t1
JOIN DataProjects.nashville_data t2
ON t1.ParcelID  = t2.ParcelID AND t1.UniqueID <> t2.UniqueID
SET t1.PropertyAddress = COALESCE(NULLIF(t1.PropertyAddress,''),t2.PropertyAddress) 
WHERE t1.PropertyAddress = '';



-- Breaking the address and splitting it into individual columns(Address, City, State)

SELECT PropertyAddress FROM DataProjects.nashville_data;

SELECT PropertyAddress, SUBSTR(PropertyAddress, 1, INSTR(PropertyAddress, ',')-1) AS Address,
SUBSTR(PropertyAddress, INSTR(PropertyAddress, ',')+1) AS CityAddress
FROM DataProjects.nashville_data;

ALTER TABLE DataProjects.nashville_data ADD PropertySplitAddress VARCHAR(255);

UPDATE DataProjects.nashville_data 
SET PropertySplitAddress = SUBSTR(PropertyAddress, 1, INSTR(PropertyAddress, ',')-1);

ALTER TABLE DataProjects.nashville_data ADD PropertySplitCity VARCHAR(255);

UPDATE DataProjects.nashville_data 
SET PropertySplitCity = SUBSTR(PropertyAddress, INSTR(PropertyAddress, ',')+1, LENGTH(PropertyAddress));



-- Using substring_index() function to split the OwnerAddress(Address, City, State)

SELECT OwnerAddress FROM DataProjects.nashville_data ;

SELECT OwnerAddress, SUBSTRING_INDEX(OwnerAddress, ',', 1) AS OwnerAddress,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ' ', -1) AS OwnerCity,
SUBSTRING_INDEX(OwnerAddress, ',', -1) AS OwnerState
FROM DataProjects.nashville_data;

ALTER TABLE DataProjects.nashville_data ADD OwnerSplitAddress VARCHAR(255);

UPDATE DataProjects.nashville_data 
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE DataProjects.nashville_data ADD OwnerSplitCity VARCHAR(255);

UPDATE DataProjects.nashville_data 
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ' ', -1);

ALTER TABLE DataProjects.nashville_data ADD OwnerSplitState VARCHAR(255);

UPDATE DataProjects.nashville_data 
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1);


-- Change Y and N to Yes and No respectively in 'SoldAsVacant' Field

SELECT SoldAsVacant, COUNT(SoldAsVacant) AS total
FROM DataProjects.nashville_data
GROUP BY SoldAsVacant ORDER BY total;

SELECT SoldAsVacant,
CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END AS SaleStatus
FROM DataProjects.nashville_data;

UPDATE DataProjects.nashville_data t1
SET SoldAsVacant = CASE 
					WHEN SoldAsVacant = 'Y' THEN 'Yes'
					WHEN SoldAsVacant = 'N' THEN 'No'
					ELSE SoldAsVacant
END;



-- Finding Duplicates in the data

SELECT * FROM DataProjects.nashville_data;

SELECT UniqueID, COUNT(UniqueID) 
FROM DataProjects.nashville_data GROUP BY UniqueID ORDER BY 2 DESC;

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) AS row_num
From DataProjects.nashville_data
-- order by ParcelID
)
SELECT * FROM RowNumCTE WHERE row_num > 1 
ORDER BY PropertyAddress;

-- Delete Unused Columns

ALTER TABLE DataProjects.nashville_data
DROP COLUMN SaleDateConverted;

SELECT * FROM DataProjects.nashville_data;


