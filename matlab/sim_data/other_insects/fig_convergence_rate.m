%% Evaluates the convergence rate for various insects
addpath('./sim_data/other_insects');
load('sim_QS_x_hover_conv_rate.mat');
mona = load('sim_QS_x_hover_mona.mat', 'WK');
hawk = load('sim_QS_x_hover_hawk.mat', 'WK');
bumb = load('sim_QS_x_hover_bumb.mat', 'WK');
fruit = load('sim_QS_x_hover_fruit.mat', 'WK');
set(0,'DefaultAxesFontName','times');
set(0,'DefaultAxesFontSize',14);

conv_rates = [conv_rate_mona, conv_rate_hawk, conv_rate_bumb, conv_rate_fruit];
N = size(conv_rates, 2);

labels = [{'MONARCH, f='+string(round(mona.WK.f,1))}, {'HAWKMOTH, f='+string(round(hawk.WK.f,1))}, ...
    {'BUMBLEBEE, f='+string(round(bumb.WK.f,1))}, {'FRUITFLY, f='+string(round(fruit.WK.f,1))}];

f = figure;
ax = gca;
f.PaperUnits = 'inches';
f.PaperPosition = [0 0 8 6];
plt_colors = ['b','r','k'];
plt_shapes = ['o','o','^'];

for c_ix=1:3
%     boxplot(ax, conv_rate, labels);
    ax.XTick = 1:N;
    scatter(ax, ax.XTick, conv_rates(c_ix+3, :), 75, plt_colors(c_ix), ...
        plt_shapes(c_ix), 'filled');
    ax.XTickLabel = labels;
    grid on;
    hold on;
end

xlim auto;
ylim auto;
xlabel('Insect and its flapping frequency (in Hz)');
ylabel(sprintf('Characteristic exponents of perturbed dynamics'));
legend({'Longitudinal mode 1', 'Longitudinal mode 2', 'Lateral mode'},...
    'Location','southeast');
print('hover_conv_insects', '-depsc', '-r0');