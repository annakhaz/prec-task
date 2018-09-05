function [trial_nums, itis, rts] = run_prec_wm(subid)

% to run: run_prec_wm('p000')

%% PTB set-up
%PsychDebugWindowConfiguration % when testing
Screen('Preference', 'SkipSyncTests', 1); % when testing on desktop
close all;
sca
Screen('Preference', 'DefaultFontSize', 44);

%% instructional text and text parameters
% in_text = ['This experiment tests how well people remember exact colors of', ...
%     ' objects they see on the screen.\nFirst, you will see a colored object.', ...
%     ' Then, after a short delay, you will see another. Next, you will be ', ...
%     ' cued to keep in mind either the first or second object with the ', ...
%     ' numbers 1 or 2, respectively.\nAfter a longer delay, you will need to',...
%     ' respond with color of ',...
%     ' counting forward.\nAfter you hit the spacebar, the numbers will stop',...
%     ' and turn red.\nThe red numbers represent how quickly you were able to',...
%     ' press the Spacebar.\n\nPress the spacebar to continue the instructions.'];
%
%
% out_text = 'All done with this task! Please wait for the experimenter';
%

% %% display instructions
% DrawFormattedText(window, in_text, 'center', 'center', text_color);
% Screen('Flip', window);




text_size = 44;
text_color = [0 0 0];

enc_time = 1;
fix_time = .5;
cue_time = .5;
delay_time = 4;
ret_time = 5;
iti = 3;

% Options:
monitor = max(Screen('Screens'));

% Which images to use (randomly ordered):
% listOfTestObjects = Shuffle(dir('ColorRotationStimuli/TestObjects/*.jpg'));
% object_stims = cellfun(@(x) regexp(x, '\d*', 'Match'), {listOfTestObjects(:).name});
stim_list = readtable('ColorRotationStimuli/stim_list.csv', 'ReadVariableNames', 0);
stim_list = Shuffle(stim_list.Var1);

% Create window and setup params for where to show things:
[win, winRect] = Screen('OpenWindow', monitor);
centerX = round(winRect(3)/2);
centerY = round(winRect(4)/2);
colorWheel.radius = 225;
colorWheel.rect = CenterRect([0 0 colorWheel.radius*2 colorWheel.radius*2], winRect);
stim.size = 256;
stimRect = CenterRect([0 0 stim.size stim.size], winRect);


WaitSecs(2);

for i = 1:3
    %%%%%%% stimulus 1
    
    image1 = imread(fullfile('ColorRotationStimuli/TestObjects', ['obj', num2str(stim_list(i)),'.jpg']));
    image1 = imresize(image1, [stim.size stim.size]); % Downsample to make color change faster
    
    angle1 = datasample(1:360, 1)%GetPolarCoordinates(centerX + 5,centerY + 5,centerX,centerY)
    savedLab = colorspace('rgb->lab', image1);
    
    newRgb = RotateImage(savedLab, round(angle1));
    curTexture = Screen('MakeTexture', win, newRgb);
    
    Screen('DrawTexture', win, curTexture, [], stimRect);
    Screen('Flip', win);
    WaitSecs(enc_time);
    
    %%%%%%% fixation
    DrawFormattedText(win, '+', 'center', 'center', text_color);
    Screen('Flip', win);
    WaitSecs(fix_time);
    
    %%%%%%% stimulus 2
    
    % ensure color of stimulus 2 is at least 40 degrees away
    angles = -39:400;
    higher_angles = angles > (angle1 + 40);
    lower_angles = angles < (angle1 - 40);
    lower_angles(41:80) = lower_angles(41:80) & higher_angles(401:440);
    higher_angles(361:400) = lower_angles(1:40) & higher_angles(361:400);
    angles = angles(higher_angles | lower_angles);
    angles = angles(angles > 0 & angles < 361);
    
    i = i + 9;
    
    image2 = imread(fullfile('ColorRotationStimuli/TestObjects', ['obj', num2str(stim_list(i)),'.jpg']));
    image2 = imresize(image2, [stim.size stim.size]); % Downsample to make color change faster
    
    angle2 = datasample(angles, 1)
    savedLab = colorspace('rgb->lab', image2);
    
    newRgb = RotateImage(savedLab, round(angle2));
    curTexture = Screen('MakeTexture', win, newRgb);
    
    Screen('DrawTexture', win, curTexture, [], stimRect);
    Screen('Flip', win);
    WaitSecs(enc_time);
    
    %%%%%%% fixation
    DrawFormattedText(win, '+', 'center', 'center', text_color);
    Screen('Flip', win);
    WaitSecs(fix_time);
    
    %%%%%%% cue
    cue = datasample(1:2, 1)
    DrawFormattedText(win, num2str(cue), 'center', 'center', text_color);
    Screen('Flip', win);
    WaitSecs(cue_time);
    
    %%%%%%% delay for 3-5s
    DrawFormattedText(win, '+', 'center', 'center', text_color);
    Screen('Flip', win);
    WaitSecs(delay_time);
    
    %%%%%%% recall
    if cue == 1
        test_image = image1;
        test_angle = angle1;
    else
        test_image = image2;
        test_angle = angle2;
    end
    
    % 10% of trials should be catch trials (new image; no associated color)
    if datasample(1:10, 1) > 9
        trial_type = 'catch'
        image3 = imread(fullfile('ColorRotationStimuli/TestObjects', ['obj', num2str(stim_list(i + 10)),'.jpg']));
        image3 = imresize(image3, [stim.size stim.size]);
        test_image = image3;
    else
        trial_type = 'angle'
    end
    
    % Show in grayscale:
    
    imgGray = repmat(mean(test_image,3), [1 1 3]);
    curTexture = Screen('MakeTexture', win, imgGray);
    Screen('DrawTexture', win, curTexture, [], stimRect);
    
    % Show color report circle:
    Screen('FrameOval', win, [128,128,128], colorWheel.rect);
    Screen('Flip', win);
    
    % determine color circle rotation amount
    color_shift = datasample(0:359, 1)
    
    % Center mouse
    SetMouse(centerX,centerY,win);
    
    % Convert the image to LAB only once to speed up color rotations:
    savedLab = colorspace('rgb->lab', test_image);
    
    % Show object in correct color for current angle and wait for click:
    buttons = [];
    oldAngle = -1;
    clicked = 0;
    resp = 'angle';
    curTime = 0;
    tic;
    
    while curTime < ret_time
        if ~clicked
            % Get mouse position
            [curX, curY, buttons] = GetMouse(win);
            curAngle = GetPolarCoordinates(curX,curY,centerX,centerY);
            
            % Display goal angle
            if test_angle - color_shift < 0
                DrawFormattedText(win, sprintf('%d', 360 - (color_shift - test_angle)), centerX, centerY + 300, text_color);
            else
                DrawFormattedText(win, sprintf('%d', test_angle - color_shift), centerX, centerY + 300, text_color);
            end
            
            % Display current angle
            DrawFormattedText(win, sprintf('%d', round(curAngle)), centerX, centerY - 300, text_color);
            
            
            % Allow user to click stim, indicating catch trial
            inside = IsInRect(curX, curY, stimRect);
            if inside && any(buttons);
                resp = 'catch';
                rt = toc;
                clicked = 1;
            end
            
            % Keep image greyscale if mouse is at center
            if (curX == centerX && curY == centerY)
                continue
            end
            
            % Otherwise, update color based on cursor location
            [dotX1, dotY1] = polar2xy(curAngle,colorWheel.radius-5,centerX,centerY);
            [dotX2, dotY2] = polar2xy(curAngle,colorWheel.radius+20,centerX,centerY);
            
            % Draw frame and dot
            Screen('FrameOval', win, [128,128,128], colorWheel.rect);
            Screen('DrawLine', win, [0 0 0], dotX1, dotY1, dotX2, dotY2, 4);
            
            % If angle changed, close old texture and make new one in correct color:
            if (curAngle ~= oldAngle) && round(curAngle) ~= 0
                newRgb = RotateImage(savedLab, curAngle + color_shift);
                Screen('Close', curTexture);
                curTexture = Screen('MakeTexture', win, newRgb);
                rt = toc;
            end
            
            % Show stimulus:
            Screen('DrawTexture', win, curTexture, [], stimRect);
            Screen('Flip', win);
            oldAngle = curAngle;
            
        end
        curTime = toc;
    end
    
    test_angle
    curAngle
    
    if test_angle - color_shift < 0
        shifted_test_angle = 360 - (color_shift - test_angle);
    else
        shifted_test_angle = test_angle - color_shift;
    end
    
    % clockwise
    raw_diff = mod(curAngle, 360) - shifted_test_angle;
    angle_diff = min(abs(raw_diff), 360 - abs(raw_diff))

    if angle_diff == 0
        disp('perfect')
    elseif abs(angle_diff) < 5
        disp('great')
    elseif abs(angle_diff) < 10
        disp('good')
    end
    
    rt
    
    if strcmp(trial_type, resp)
        disp('correct resp type');
    else
        disp('incorrect resp type');
    end
    
    %%%%%%% iti
    DrawFormattedText(win, '+', 'center', 'center', text_color);
    Screen('Flip', win);
    WaitSecs(iti);
end

Screen('Close', curTexture);

% Wait for release of mouse button
while any(buttons), [~,~,buttons] = GetMouse(win); end






%
% %% preallocate variables for recording
% num_trials = 10;
% trial_nums = zeros(num_trials, 1);
% itis = datasample(3:.5:5, num_trials)';
% rts = zeros(num_trials, 1);
%
% %% loop through trials
% exper_start = GetSecs;
% trial = 0;
%
% while trial < num_trials
%     trial = trial + 1;
%     trial_nums(trial) = trial;
%
%     % stim 1
%
%     % fixation
%     DrawFormattedText(window, '+', 'center', 'center', text_color);
%     Screen('Flip', window);
%     WaitSecs(fix_time);
%
%     % stim 2
%
%     % fixation
%     DrawFormattedText(window, '+', 'center', 'center', text_color);
%     Screen('Flip', window);
%     WaitSecs(fix_time);
%
%     % cue
%
%     % delay for 3-5s
%
%     % recall
%
% end
%
% %% wrap up
%
% % display out text
% DrawFormattedText(window, out_text, 'center', 'center', black);
% Screen('Flip', window);
%
% %data = [trial_nums, itis, rts, offsets, early_resps]
% %csvwrite(['pvt_', subid, '.csv'], data);
%
% %sprintf('Mean RT: %.2f', mean(rts(1:max(trial_nums))))
%
% WaitSecs(3);

close all; sca

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