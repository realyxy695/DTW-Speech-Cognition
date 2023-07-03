function [distance,split] = DP(template, data)
% 基于动态规划的最短路径算法，求解任意种类数的模板匹配最短路径
% template：模板数组
% data：待匹配数据
% 返回值split：模板分界点，包括源数据的起始点
    inf = 256;
    type = size(template,1);
    
    split = ones(type, type);
    distance = inf*ones(1, type); 
    distance(1) = 0;
    
    for t = 2:size(data,1)
        for num = 1:type
            nowdistance(num) = norm(template(num,:)-data(t,:));
        end
        
        distance(1) = distance(1) + nowdistance(1);
        for m = type:-1:2
            if distance(m)>distance(m-1)
                distance(m) = distance(m-1) + nowdistance(m);
                split(m,1:m-1) = split(m-1,1:m-1);
                split(m, m) = t;
            else
                distance(m) = distance(m) + nowdistance(m);
            end
        end
    end
    distance = distance(type);
    split = split(type,:);
    split(type+1) = length(data);
end

