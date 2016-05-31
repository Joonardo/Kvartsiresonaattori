g_data = [];
ps_data = [];
f_data = linspace(32.74e3, 32.752e3, 100);

for f = f_data
    [g, ps] = DAQreadout(f);
    g_data(end + 1) = g;
    ps_data(end + 1) = ps;
    length(ps_data)
end

figure
plot(f_data, g_data)
title('Vahvistus')
figure
plot(f_data, ps_data)
title('Vaihe-ero')