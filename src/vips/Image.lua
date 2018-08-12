-- the definition of the image class
--
-- we have to split the definition of Image from the methods to avoid
-- recursive requires between the methods and voperation

local Image = {
    mt = {}
}

return Image
