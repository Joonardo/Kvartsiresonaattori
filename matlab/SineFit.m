function [sinecurve] = SineFit(params, time, freq)

amp = params(1);
phase = params(2); 
offset = params(3);

sinecurve = amp*sin(2*pi*freq*time + phase) + offset;

end