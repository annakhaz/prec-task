function PsychtoolboxDemo()
  % Options:
  monitor = max(Screen('Screens'));

  % Which images to use (randomly ordered):
  listOfTestObjects = Shuffle(dir('TestObjects/*.jpg'));

  % Create window and setup params for where to show things:
  [win, winRect] = Screen('OpenWindow', monitor);
  centerX = round(winRect(3)/2);
  centerY = round(winRect(4)/2);
  colorWheel.radius = 225;
  colorWheel.rect = CenterRect([0 0 colorWheel.radius*2 colorWheel.radius*2], winRect);
  stim.size = 256;
  stimRect = CenterRect([0 0 stim.size stim.size], winRect);
  
  % Show a loading images status:
  DrawFormattedText(win, 'Loading images...', 'center', 'center');
  Screen('Flip', win);
  
  % For each image....
  for i = 1:length(listOfTestObjects)
    
    % Show in grayscale:
    originalImg = imread(fullfile('TestObjects', listOfTestObjects(i).name));
    originalImg = imresize(originalImg, [stim.size stim.size]); % Downsample to make color change faster
    imgGray = repmat(mean(originalImg,3), [1 1 3]);
    curTexture = Screen('MakeTexture', win, imgGray);
    Screen('DrawTexture', win, curTexture, [], stimRect);
    
    % Show color report circle:
    DrawFormattedText(win, 'Click to see next object; Press q to quit', 'center', 100, [0 0 0]);
    Screen('FrameOval', win, [128,128,128], colorWheel.rect);
    Screen('Flip', win);
      
    % Center mouse
    SetMouse(centerX,centerY,win);
      
    % Convert the image to LAB only once to speed up color rotations:
    savedLab = colorspace('rgb->lab', originalImg);
    
    % Wait until the mouse moves:
    [curX,curY] = GetMouse(win);
    while (curX == centerX && curY == centerY)
      [curX,curY] = GetMouse(win);
    end
      
    % Show object in correct color for current angle and wait for click:
    buttons = [];
    oldAngle = -1;
    while ~any(buttons)
      [curX,curY, buttons] = GetMouse(win);
      curAngle = GetPolarCoordinates(curX,curY,centerX,centerY);
      [dotX1, dotY1] = polar2xy(curAngle,colorWheel.radius-5,centerX,centerY);
      [dotX2, dotY2] = polar2xy(curAngle,colorWheel.radius+20,centerX,centerY);
      
      % Draw frame and dot
      Screen('FrameOval', win, [128,128,128], colorWheel.rect);
      Screen('DrawLine', win, [0 0 0], dotX1, dotY1, dotX2, dotY2, 4);
      DrawFormattedText(win, 'Click to see next object; Press q to quit', 'center', 100, [0 0 0]);
      
      % If angle changed, close old texture and make new one in correct color:
      if (curAngle ~= oldAngle) && round(curAngle) ~= 0
        newRgb = RotateImage(savedLab, round(curAngle));
        Screen('Close', curTexture);
        curTexture = Screen('MakeTexture', win, newRgb);
      end

      % Show stimulus:
      Screen('DrawTexture', win, curTexture, [], stimRect);
      Screen('Flip', win);
      oldAngle = curAngle;
      
      % Allow user to quit on each frame:
      [~,~,keys]=KbCheck;
      if keys(KbName('q'))
        sca; error('User quit');
      end
    end
    Screen('Close', curTexture);
    
    % Wait for release of mouse button
    while any(buttons), [~,~,buttons] = GetMouse(win); end
  end
  
  % Clean up
  Screen('CloseAll');
end

% ----------------------------------------------------------
function newRgb = RotateImage(lab, r)
  x = lab(:,:,2);
  y = lab(:,:,3);
  v = [x(:)'; y(:)'];
  vo = [cosd(r) -sind(r); sind(r) cosd(r)] * v;
  lab(:,:,2) = reshape(vo(1,:), size(lab,1), size(lab,2));
  lab(:,:,3) = reshape(vo(2,:), size(lab,1), size(lab,2));
  newRgb = colorspace('lab->rgb', lab) .* 255;
end

% ----------------------------------------------------------
function [angle, radius] = GetPolarCoordinates(h,v,centerH,centerV)
  % get polar coordinates
  hdist   = h-centerH;
  vdist   = v-centerV;
  radius     = sqrt(hdist.*hdist + vdist.*vdist)+eps;
  
  % determine angle using cosine (hyp will never be zero)
  angle = acos(hdist./radius)./pi*180;
  
  % correct angle depending on quadrant
  angle(hdist == 0 & vdist > 0) = 90;
  angle(hdist == 0 & vdist < 0) = 270;
  angle(vdist == 0 & hdist > 0) = 0;
  angle(vdist == 0 & hdist < 0) = 180;
  angle(hdist < 0 & vdist < 0)=360-angle(hdist < 0 & vdist < 0);
  angle(hdist > 0 & vdist < 0)=360-angle(hdist > 0 & vdist < 0);
end

% ----------------------------------------------------------
function [x, y] = polar2xy(angle,radius,centerH,centerV)  
  x = round(centerH + radius.*cosd(angle));
  y = round(centerV + radius.*sind(angle));
end

