-- DogHub周遊コースの写真URLを確認
SELECT 
  name,
  thumbnail_url,
  gallery_images
FROM official_routes
WHERE name = 'DogHub周遊コース';
