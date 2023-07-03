function [feature] = cepstrum(res,p)
Fs = 16000;
wlen = 256;
inc = 128;

% step1: 求LPCC
a = durbin(res);% 求LPC系数
y = filter([0 -a(2:end)],1,res);% 重建信号

dft1 = fft(y);
yhat1 = ifft(log(abs(dft1)));
lpccs = yhat1(2:p);

% step2: 求FFTC

dft2 = fft(res);
yhat2 = ifft(log(abs(dft2+1e-10)));
fftc = yhat2(2:p);

% step3: 求MFCC
mfccs = mfcc(res,Fs,'WindowLength',wlen,'OverlapLength',inc ,'NumCoeffs',p,'LogEnergy','Ignore'); 
mfccs = mfccs(2:p);
dmfcc = diff(mfccs);
feature = cat(2,lpccs',mfccs,dmfcc,fftc');

% figure(2);
% hold on;
% plot(realfreq, abs(Y)/max(abs(Y))*100,'k' );
% plot(realfreq, abs(H)/max(abs(H))*100,'r');
% title('512点频谱');
% legend('信号频谱','声道频谱');
% xlabel('频率/Hz');
% ylabel('归一化幅度');
% hold off;
% 
% figure(3);
% plot(yhat);
% title('倒谱');
% ylabel('幅度');
end

