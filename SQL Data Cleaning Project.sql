/*

Cleaning Data in SQL Queries

*/
USE portfolioproject;

Select * From NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format
-- Step 1: Add the new column
ALTER TABLE NashvilleHousing ADD COLUMN ConvertedSaleDate DATE;

-- Step 2: Update the new column with converted values
UPDATE NashvilleHousing
SET ConvertedSaleDate = DATE(SaleDate);
 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

-- Step 1: Select all columns and order by ParcelID
SELECT *
FROM NashvilleHousing
ORDER BY ParcelID;

-- Step 2: Join query to find missing Property Addresses
-- Select ParcelID and PropertyAddress from alias 'a'
-- Select ParcelID and PropertyAddress from alias 'b' and rename them in the result set to distinguish them
-- Use COALESCE to fill missing PropertyAddress in 'a' with PropertyAddress from 'b' if it exists
SELECT 
    a.ParcelID, 
    a.PropertyAddress, 
    b.ParcelID AS b_ParcelID, 
    b.PropertyAddress AS b_PropertyAddress, 
    COALESCE(a.PropertyAddress, b.PropertyAddress) AS FilledPropertyAddress
FROM NashvilleHousing a
JOIN NashvilleHousing b
  ON a.ParcelID = b.ParcelID         -- Join on ParcelID
  AND a.UniqueID <> b.UniqueID       -- Ensure different rows (unique IDs)
WHERE a.PropertyAddress IS NULL;     -- Only consider rows where PropertyAddress in 'a' is NULL

-- Step 3: Update missing Property Addresses
-- Update PropertyAddress in alias 'a' with PropertyAddress from alias 'b' where PropertyAddress in 'a' is NULL
UPDATE NashvilleHousing a
JOIN NashvilleHousing b
  ON a.ParcelID = b.ParcelID         -- Join on ParcelID
  AND a.UniqueID <> b.UniqueID       -- Ensure different rows (unique IDs)
SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)  -- Use COALESCE to fill missing PropertyAddress
WHERE a.PropertyAddress IS NULL;     -- Only update rows where PropertyAddress in 'a' is NULL
--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

ALTER TABLE NashvilleHousing
ADD COLUMN PropertySplitAddress VARCHAR(255),
ADD COLUMN PropertySplitCity VARCHAR(255),
ADD COLUMN OwnerSplitAddress VARCHAR(255),
ADD COLUMN OwnerSplitCity VARCHAR(255),
ADD COLUMN OwnerSplitState VARCHAR(255);

UPDATE NashvilleHousing
SET 
    PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1), -- Extracts the part before the first comma (street address)
    PropertySplitCity = TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1)); -- Extracts the part after the last comma (city) and trims any whitespace
    
UPDATE NashvilleHousing
SET 
    OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1), -- Extracts the part before the first comma (street address)
    OwnerSplitCity = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1)), -- Extracts the part between the first and last commas (city) and trims any whitespace
    OwnerSplitState = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1)); -- Extracts the part after the last comma (state) and trims any whitespace
    
SELECT *
FROM NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field


-- Step 1: Select distinct SoldAsVacant values and count their occurrences
-- This groups the SoldAsVacant values and counts how many times each value occurs
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant) AS CountSoldAsVacant
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY CountSoldAsVacant;

-- Step 2: Select SoldAsVacant values and convert 'Y' to 'Yes' and 'N' to 'No'
-- This uses a CASE statement to transform the values in the SoldAsVacant column
SELECT SoldAsVacant,
       CASE 
           WHEN SoldAsVacant = 'Y' THEN 'Yes'
           WHEN SoldAsVacant = 'N' THEN 'No'
           ELSE SoldAsVacant
       END AS SoldAsVacantText
FROM NashvilleHousing;

-- Step 3: Update the SoldAsVacant column to replace 'Y' with 'Yes' and 'N' with 'No'
-- This uses a CASE statement to update the values in the SoldAsVacant column
UPDATE NashvilleHousing
SET SoldAsVacant = CASE 
                       WHEN SoldAsVacant = 'Y' THEN 'Yes'
                       WHEN SoldAsVacant = 'N' THEN 'No'
                       ELSE SoldAsVacant
                   END;

-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

-- Step 1: Identify duplicates by assigning row numbers to each row
-- using a subquery to assign row numbers based on specified columns
DELETE nh
FROM NashvilleHousing nh
JOIN (
    SELECT UniqueID
    FROM (
        SELECT 
            UniqueID,
            ROW_NUMBER() OVER (
                PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
                ORDER BY UniqueID
            ) AS row_num
        FROM NashvilleHousing
    ) AS RowNumCTE
    WHERE row_num > 1
) dup
ON nh.UniqueID = dup.UniqueID;

-- Step 2: Verify the changes by selecting all rows
SELECT * FROM NashvilleHousing;

---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

Select *
From NashvilleHousing;

ALTER TABLE NashvilleHousing
  DROP COLUMN OwnerAddress,
  DROP COLUMN TaxDistrict,
  DROP COLUMN PropertyAddress,
  DROP COLUMN SaleDate;
---------------------------------------------------------------------------------------------------------

-- Completed