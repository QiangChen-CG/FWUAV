clear all;
close all;
addpath('../');

WK.f=10.1;
WK.beta=30*pi/180;

WK.phi_m=60*pi/180;
WK.phi_K=0.9;
WK.phi_0=10*pi/180;

WK.theta_m=40*pi/180;
WK.theta_C=4;
WK.theta_0=20*pi/180;
WK.theta_a=0;

WK.psi_m=30*pi/180;
WK.psi_N=1;
WK.psi_a=0;
WK.psi_0=10*pi/180;

WK.type='BermanWang';
WK.theta_a=0.3;

N=1001;
T=1/WK.f;
t=linspace(0,T,N);

load('morp_MONARCH');

x_dot=[1.2 0 0]';
R=eye(3);
W=[0 0 0]';

for k=1:N
    [E_R(:,k) E_R_dot(:,k), E_R_ddot(:,k)]=wing_kinematics(t(k),WK);
    [E_L(:,k) E_L_dot(:,k), E_L_ddot(:,k)]=wing_kinematics(t(k),WK);        
    
    [Q_R(:,:,k) Q_L(:,:,k) W_R(:,k) W_L(:,k) W_R_dot(:,k) W_L_dot(:,k)]=wing_attitude(WK.beta, E_R(:,k), E_L(:,k), E_R_dot(:,k), E_L_dot(:,k), E_R_ddot(:,k), E_L_ddot(:,k));
    [L_R(:,k) L_L(:,k) D_R(:,k) D_L(:,k) M_R(:,k) M_L(:,k) ...
        F_rot_R(:,k) F_rot_L(:,k) M_rot_R(:,k) M_rot_L(:,k) ...
        alpha_R(k) alpha_L(:,k) U_alpha_dot_R(:,k) U_alpha_dot_L(:,k) U_R(:,k) U_L(:,k)]...
        =wing_QS_aerodynamics(MONARCH, W_R(:,k), W_L(:,k), W_R_dot(:,k), W_L_dot(:,k));

    
    [L_R_int(:,k) L_L_int(:,k) D_R_int(:,k) D_L_int(:,k) M_R(:,k) M_L(:,k) ...
        F_rot_R(:,k) F_rot_L(:,k) M_rot_R(:,k) M_rot_L(:,k) ...
        alpha_R(k) alpha_L(:,k) U_alpha_dot_R(:,k) U_alpha_dot_L(:,k) U_R(:,k) U_L(:,k)]...
        =wing_QS_aerodynamics(MONARCH, W_R(:,k), W_L(:,k), W_R_dot(:,k), W_L_dot(:,k), x_dot, R, W, Q_R(:,:,k), Q_L(:,:,k));

end
% L_in_B=L_R_in_B +L_L_in_B;
% D_in_B=D_R_in_B +D_L_in_B;
% F_rot_in_B=F_rot_R_in_B +F_rot_L_in_B;
% 
% 
% hE=figure;
% subplot(3,1,1);
% plot(t/T,E_R(1,:)*180/pi);
% grid on;set(gca,'XTick',[0 0.5 1]);
% ylabel('$\phi$','interpreter','latex');
% text(0.2,-40,'upstroke','fontname','times');
% text(0.7,-40,'downstroke','fontname','times');
% 
% subplot(3,1,2);
% plot(t/T,E_R(2,:)*180/pi);
% grid on;set(gca,'XTick',[0 0.5 1]);
% ylabel('$\theta$','interpreter','latex');
% 
% subplot(3,1,3);
% plot(t/T,E_R(3,:)*180/pi);
% grid on;set(gca,'XTick',[0 0.5 1]);
% ylabel('$\psi$','interpreter','latex');
% xlabel('$t/T$','interpreter','latex');
% 
% h_alpha=figure;
% plot(t/T,alpha_R,'b');
% ylabel('$\alpha$','interpreter','latex');
% xlabel('$t/T$','interpreter','latex');
% grid on;set(gca,'XTick',[0 0.5 1]);
% 
% h_U_alpha_dot=figure;
% plot(t/T,U_alpha_dot_R);
% ylabel('$\dot \alpha \| U\|$','interpreter','latex');
% xlabel('$t/T$','interpreter','latex');
% grid on;set(gca,'XTick',[0 0.5 1]);
% 
% 
% h_U=figure;
% for ii=1:3
%     subplot(3,1,ii);
%     plot(t/T,U_R(ii,:),'r',t/T,U_L(ii,:),'b');
% grid on;set(gca,'XTick',[0 0.5 1]);
%     hold on;
% end
% xlabel('$t/T$','interpreter','latex');
% subplot(3,1,2);
% ylabel('$U$','interpreter','latex');
% 
h_F=figure;
for ii=1:3
    subplot(3,1,ii);
    plot(t/T,L_R(ii,:),'r',t/T,D_R(ii,:),'b',t/T,F_rot_R(ii,:),'m--');
    grid on;set(gca,'XTick',[0 0.5 1]);
    hold on;
    plot(t/T,L_R(ii,:)+D_R(ii,:)+F_rot_R(ii,:),'k','LineWidth',1.2);
end
xlabel('$t/T$','interpreter','latex');
subplot(3,1,2);
hl=legend({'$L_R$','$D_R$','$F_{\mathrm{rot}}$','$F_{\mathrm{total}}$'});
set(hl,'interpreter','latex');

h_F_int=figure;
for ii=1:3
    subplot(3,1,ii);
    plot(t/T,L_R_int(ii,:),'r',t/T,D_R_int(ii,:),'b',t/T,F_rot_R(ii,:),'m--');
    grid on;set(gca,'XTick',[0 0.5 1]);
    hold on;
    plot(t/T,L_R_int(ii,:)+D_R_int(ii,:)+F_rot_R(ii,:),'k','LineWidth',1.2);
end
xlabel('$t/T$','interpreter','latex');
subplot(3,1,2);
hl=legend({'$L_R$','$D_R$','$F_{\mathrm{rot}}$','$F_{\mathrm{total}}$'});
set(hl,'interpreter','latex');

% 
% h_FB=figure;
% for ii=1:3
%     subplot(3,1,ii);
%     plot(t/T,L_in_B(ii,:),'r',t/T,D_in_B(ii,:),'b',t/T,F_rot_in_B(ii,:),'m--');
%     hold on;
%     plot(t/T,L_in_B(ii,:)+D_in_B(ii,:)+F_rot_in_B(ii,:),'k','LineWidth',1.2);
%     grid on;set(gca,'XTick',[0 0.5 1]);
% end
% xlabel('$t/T$','interpreter','latex');
% subplot(3,1,2);
% hl=legend({'$L_R$','$D_R$','$F_{\mathrm{rot}}$','$F_{\mathrm{total}}$'});
% set(hl,'interpreter','latex');
% 
% 
