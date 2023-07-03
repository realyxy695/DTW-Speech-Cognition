clc;
clear all;
close all;

mode = 1;% 0=train, 1=test
train_file = ["data/train/qh2.wav"];
test_file = ["data/test/hua.wav"];

% 读取语音信号
% Fs = 16000,16Bits，单声道，线性PCM，WAVE文件

type = 6; % 模板数
p = 24; % LPCC与MFCC个数
n = 12; % 取系数个数
Fs = 16000;
if mode == 0
    [res, Fs] = audioread(train_file);
    N = length(res);               % 信号长度
    dc = sum(res)./ N;
    res = res - dc;

    [startpoint, endpoint] = block(res,Fs);

    feature = [];
    lpcc_template = [];
    index = [0];
    for num = 0:9
        resnow = res(startpoint(num+1):endpoint(num+1));
        resnow = filter([1 -0.98] ,1,resnow); % 预加重

        % 分帧
        wlen = 256;% 帧长
        inc = 128;% 帧移
        win=hamming(wlen);          %汉明窗
        frames = enframe(resnow ,win, inc)';     % 分帧
        fn = size(frames,2); % 帧数
        index(num+2) = index(num+1)+fn;
        % 逐帧分析提取特征参数
        feature_frames = [];
        for cnt = 1:fn
            frame = frames(:,cnt);
            frame = frame - mean(frame);
            feature_frames = cat(1, feature_frames, cepstrum(frame,p)); % 提取特征
        end
        % 模板训练
        lpcc = feature_frames(:,p:p+n-1);
        split = [1];
        template = [];
        % Initializing the split point and template
        for i = 1:type
            split(i+1) = floor(i*size(lpcc,1)/type);
            template(i,:) = mean(lpcc(split(i):split(i+1),:),1);
        end
        
        while(eps>0)
            epoch = 0;
            % DTW starts
            [~,new_split] = DP(template, lpcc);
            for i = 1:type
                template(i,:) = mean(lpcc(split(i):split(i+1),:),1);
            end
            eps = norm(split-new_split);
            split = new_split;
            epoch = epoch+1;
        end
        lpcc_template = cat(1,lpcc_template,template);
        % 模板保存
        feature = cat(1, feature, feature_frames);
    end
        save featuredata.mat index feature lpcc_template;   
end

if mode == 1
    %[res, Fs] = audioread(test_file);
    rec = audiorecorder(Fs,16,1);
    disp('Start recoding!');
    recordblocking(rec,3);
    disp('End recording!');
    res = getaudiodata(rec);
    
    N = length(res);               % 信号长度
    dc = sum(res)./ N;
    res = res - dc;

    [startpoint, endpoint] = block(res,Fs);
    
    load('featuredata.mat');
    for num = 1:length(startpoint)
        resnow = res(startpoint(num):endpoint(num));
        resnow = filter([1 -0.98] ,1,resnow); % 预加重

        % 分帧
        wlen = 256;% 帧长
        inc = 128;% 帧移
        win=hamming(wlen);          %汉明窗
        frames = enframe(resnow ,win, inc)';     % 分帧
        fn = size(frames,2); % 帧数
        % 逐帧分析提取特征参数
        feature_sample = [];
        for cnt = 1:fn
            frame = frames(:,cnt);
            frame = frame - mean(frame);
            feature_sample = cat(1, feature_sample, cepstrum(frame,p)); % 提取声道频谱作为特征
        end


        for i = 1:10
            template_lpcc = feature(index(i)+1:index(i+1),1:n);
            template_mfcc = feature(index(i)+1:index(i+1), p:p+n-1);
            template_dmfcc = feature(index(i)+1:index(i+1), 2*p-1:2*p+n);
            template_fftc = feature(index(i)+1:index(i+1), 3*p-3:3*p-3+n);
            train_template = lpcc_template((i-1)*6+1:i*6,:);
            match_sample = feature_sample(:,p:p+n-1);

            dist(1,i) = DP(template_lpcc, feature_sample(:,1:n));
            dist(2,i) = DP(template_mfcc,feature_sample(:,p:p+n-1));
            dist(3,i) = DP(template_dmfcc,feature_sample(:,2*p-1:2*p+n));
            dist(4,i) = DP(template_fftc,feature_sample(:,3*p-3:3*p-3+n));
            [dist(5,i),split] = DP(train_template, match_sample);
        end

        [~,I1] = sort(dist(1,:));weight(1) = std(dist(1,:));
        [~,I2] = sort(dist(2,:));weight(2) = std(dist(2,:));
        [~,I3] = sort(dist(3,:));weight(3) = std(dist(3,:));
        [~,I4] = sort(dist(4,:));weight(4) = std(dist(4,:));
        [~,I5] = sort(dist(5,:));weight(5) = std(dist(5,:));
        weight = weight./sum(weight); % 根据标准差得到打分权重
        for j = 1:10
            score(1,I1(j)) = 10-j;
            score(2,I2(j)) = 10-j;
            score(3,I3(j)) = 10-j;
            score(4,I4(j)) = 10-j;
            score(5,I5(j)) = 10-j;
        end

        [~,maxnumber] = max(score(5,:));
        maxnumber = maxnumber-1;

        figure();
        subplot(221);
        bar(0:9, dist(1,:));
        xlabel('语音数字');
        ylabel('二范数距离');
        title(['第',num2str(num),'个数字LPCC语音判别结果']);
        for i =1:10
            text(i-1,dist(1,i),num2str(dist(1,i)),'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',8,'FontName','Times New Roman');
        end

        subplot(222);
        bar(0:9, dist(2,:));
        xlabel('语音数字');
        ylabel('二范数距离');
        title(['第',num2str(num),'个数字MFCC语音判别结果']);
        for i =1:10
            text(i-1,dist(2,i),num2str(dist(2,i)),'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',8,'FontName','Times New Roman');
        end

        subplot(223);
        bar(0:9, dist(3,:));
        xlabel('语音数字');
        ylabel('二范数距离');
        title(['第',num2str(num),'个数字差分MFCC语音判别结果']);
        for i =1:10
            text(i-1,dist(3,i),num2str(dist(3,i)),'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',8,'FontName','Times New Roman');
        end

        subplot(224);
        bar(0:9, dist(4,:));
        xlabel('语音数字');
        ylabel('二范数距离');
        title(['第',num2str(num),'个数字差分FFTC语音判别结果']);
        for i =1:10
            text(i-1,dist(4,i),num2str(dist(4,i)),'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',8,'FontName','Times New Roman');
        end
        
        figure();
        bar(0:9, dist(5,:));
        xlabel('语音数字');
        ylabel('二范数距离');
        title(['第',num2str(num),'个数字模板训练LPCC语音判别结果']);
        for i =1:10
            text(i-1,dist(5,i),num2str(dist(5,i)),'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',8,'FontName','Times New Roman');
        end
        
        disp(['语音数字是',num2str(maxnumber)]);
    end
end