function [startpoint, endpoint] = block(res_no_dc,Fs)
%语音分帧函数
%   将数字语音波形分开
%   一个语音持续大约0.59s， 9440采样点，59帧

noise = max(max(res_no_dc(1:6000)),max(res_no_dc(length(res_no_dc)-6000:end))); % 取语音始末最大值作为噪声
gate = 2 * noise; % 设置门限
wlen = 320; % 帧长
inc = 160; % 帧移

win=boxcar(wlen);          %给出矩形窗
frame = enframe(res_no_dc ,win,inc)';     % 分帧
fn = size(frame,2); % 帧数

energy = []; % 短时能量
ptr = []; % 过门限率

for i=1 : fn
    u = frame(:,i);              % 取出一帧
    u2 = u.*u;               % 求出能量
    energy(i) = sum(u2);         % 对一帧累加求短时能量
    
    
    overgate = (abs(u) - gate) > 0;
    overgatesign = sign(overgate);
    ptr(i) = sum(abs(diff(overgatesign)));
end


nenergy = energy ./ max(energy) ; % 归一化
diff_en = cat(2, diff(nenergy), [0]);
diff_en = diff_en./max(diff_en);

averdiff_en = sum(abs(diff_en))./fn; 

noise_energy = noise*noise*wlen;
ensign = (abs(diff_en) >= averdiff_en) |(energy>2*noise_energy);


normal = max(ptr);

nptr = ptr./normal; % 归一化
diff_ptr = cat(2, diff(nptr), [0]);
diff_ptr = diff_ptr./max(diff_ptr);

averdiff_ptr = sum(abs(diff_ptr))./fn;
ptrsign = abs(diff_ptr) >= averdiff_ptr ;

slopesign = ptrsign | ensign;
index = [1:fn];
signindex = index(slopesign);
Start = []; End = [];
for cnt = 1:length(signindex)
    if (sum(slopesign(signindex(cnt)-10:signindex(cnt))) == 1)
        Start = cat(1,Start,[signindex(cnt)]);
    end
    if sum(slopesign(signindex(cnt):min(signindex(cnt)+10,length(slopesign)) )) == 1
        End = cat(1,End,[signindex(cnt)]);
    end
end

now = 1;
for n = 1:length(Start)
    if End(now) - Start(now) < 30
        End(now) = [];
        Start(now) = [];
        now = now-1;
    end
    now = now+1;
end

startpoint= Start * 160;
endpoint = End * 160;

figure(1)
Ones = ones(length(startpoint),1);
hold on;
plot(res_no_dc);   % 原始波形
x = (1:fn)*160;
plot(x,energy./max(energy),'g');
plot(x,ptr./max(ptr),'y');
% 绘制起点
stem(startpoint , Ones,'k',marker = 'none');
stem(startpoint , -Ones,'k',marker = 'none');
% 绘制终点
stem(endpoint , Ones,'r',marker = 'none');
stem(endpoint , -Ones,'r',marker = 'none');


title('起始点');
legend('原始波形','能量','过门限率','起点','','终点');
hold off;

end

