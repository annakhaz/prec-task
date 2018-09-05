function HowToRotate()
  % Which image to use:
  fName = 'TestObjects/obj1.jpg';
  
  % Setup figure and load image:
  figure(1);
  set(gcf, 'Color', [1 1 1]);
  img = imread(fName);
  
  % Show every 10 degrees:
  anglesShow = 10:10:360;
  for r = 1:length(anglesShow)
    subplot(6,6,r);
    imgOut = RotateImage(img, anglesShow(r));
    imshow(imgOut);
  end
end

function img = RotateImage(img, angle)
  % Convert to LAB and correct format:
  img = double(img)/255;
  lab = colorspace('rgb->lab', img);
  x = lab(:,:,2);
  y = lab(:,:,3);
  v = [x(:)'; y(:)'];
  
  % Rotate:
  percentRotation = angle/360;
  theta = 2*pi*percentRotation;
  vo = [cos(theta) -sin(theta); sin(theta) cos(theta)] * v;
  
  % Reshape into correct format:
  lab(:,:,2) = reshape(vo(1,:), size(img,1), size(img,2));
  lab(:,:,3) = reshape(vo(2,:), size(img,1), size(img,2));
  img = uint8(colorspace('lab->rgb', lab) .* 255);
end