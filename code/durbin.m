function [a] = durbin(res)
%DURBIN 此处显示有关此函数的摘要
p = 12; % 阶数
R = xcorr(res, p)';
R = R(floor(length(R)./2)+1 : end );

a = zeros(p);
K = zeros(1,p);
B = zeros(1,p);

a(1,1) = -R(2)/R(1); % a_0^0
K(1) = a(1,1); % K^1
B(1) = (1-K(1)^2) * R(1); % B^1

for m = 2:p
    a(m,m) = -R(m+1) / B(m-1);
    for i=1:m-1
        a(m,m) = a(m,m)-(a(m-1,i)*R(m+1-i))/B(m-1);
    end
    K(m) = a(m,m);
    if K(m)>1 
        break 
    end
    for j=1:m-1
        a(m,j)=a(m-1,j)+K(m)*a(m-1,m-j);
    end
    B(m)=B(m-1) * (1-K(m)^2);
end
 a = cat(2,[1],a(p,:));
end

