function [G, PhaseShift] = DAQreadout(freq)

    % Pohja studiokurssin projektityˆn DAQ-mittauksiin.
    % Modifioi koodia tarvittaessa projektityˆn eri vaiheisiin sopivaksi.

    %clear all;

    % ************************ Analog Input - alustus ************************* %
    % luodaan muuttuja AI, joka viittaa DAQ:iin:
    AI = analoginput('mcc', 0); %
    % lis‰t‰‰n muuttujaan kaksi kanavaa (0. ja 1. kanava): %
    InChannel0 = addchannel(AI,0);
    InChannel1 = addchannel(AI,1);
    % n‰ytteenottotaajuus ja -aika:
    InputRate = 500e3;
    InputTime = 1; % sekunnin p‰tk‰
    TimeVector = linspace(0,1,InputRate*(InputTime));

    set(AI,'SampleRate',InputRate);

    % kerralla ker‰tt‰vien datapisteiden lukum‰‰r‰:
    set(AI,'SamplesPerTrigger', InputTime*InputRate);
    % triggeri tulee ohjelmallisesti:
    set(AI,'TriggerType','Immediate');

    % kanavien j‰nniterajat:
    Vrange = 10;
    AI.Channel(1).InputRange=[-Vrange Vrange];
    AI.Channel(2).InputRange=[-Vrange Vrange];
    %
    %
    % ************************ Analog Output - alustus ************************* %
    %
    OutputRate = InputRate;
    OutputTime = InputTime;
    AO = analogoutput('mcc',0);
    OutChannel = addchannel(AO, 0);
    set(AO,'SampleRate', OutputRate);
    %
    % ************************ generoitava signaali ***************************** %
    %
    Amplitude = 0.1;
    % freq = f;
    timetrace = Amplitude* sin(2*pi*freq*TimeVector);
    %
    % ************* Ohjelmallinen trigger signaalin generoimiseksi ***************  %
    %
    stop(AO); % output-kanava pit‰‰ resetoida
    putdata(AO, timetrace');
    start(AO); % trigger
    %
    % ************** Ohjelmallinen trigger signaalin lukemiseksi **************** %
    %
    start(AI); % trigger
    DataIn = getdata(AI);

    %
    % *************************** Datan prosessointi ***************************** %
    %
    % DataIn - muuttujan kukin rivi vastaa yht‰ alustettua kanavaa.
    % Ota k‰sittelyyn pieni p‰tk‰ dataa esim. datajoukon keskivaiheilta.
     nProcess = 1e3;
     SteadyState = floor(length(TimeVector)/2);
%      nProcess = 100e3;
%      SteadyState = 1;
     DataProc = DataIn(SteadyState:SteadyState+nProcess, 1);
     DataRef = DataIn(SteadyState:SteadyState+nProcess, 2);
    % normalisoidaan ajanp‰tk‰ alkamaan nollasta yksinkertaisuuden vuoksi.
    TimeProc = TimeVector(SteadyState:SteadyState+nProcess) - TimeVector(SteadyState);

    % fittausfunktion alustus on monimutkaista:
    ToleranceX = 1e-7;
    ToleranceY = 1e-7;
    options= [];
    options=optimset('MaxFunEvals',1e3,'MaxIter',1e3,'TolFun',ToleranceY,'TolX',ToleranceX);

    % sovituksen alkuarvaukset:
    InitGuess(1) = Amplitude;
    InitGuess(2) = 0; % vaihe
    InitGuess(3) = 0; %offset

    % n‰ihin voi tarvittaessa laittaa ‰‰rirajoja sovitusparametrien arvoille.
    % amplitudi kannattaa rajoittaa positiiviseksi (negatiivinen amplitudi merkitsee pi:n vaihesiirtoa),
    LowBound = [0 -Inf -Inf];
    UpBound = [Inf Inf Inf];

    % fittauskomennon viimeinen argumentti on funktiolle viet‰v‰ vakioparametri.
    [SineCurve] = lsqcurvefit(@SineFit, InitGuess, TimeProc, DataProc', LowBound, UpBound,  options, freq);
    FitAmplitude = SineCurve(1);
    % fittaus voi antaa mielivaltaisen suuren arvon vaiheelle.
    % vaihe on kuitekin j‰rkev‰‰ m‰‰ritell‰ vain 0...2pi v‰lill‰.
    FitPhase = mod(SineCurve(2), 2*pi);

    % referenssikanavakin pit‰‰ prosessoida vaihesiirron selvitt‰miseksi.
    [SineCurveRef] = lsqcurvefit(@SineFit, InitGuess, TimeProc, DataRef', LowBound, UpBound,  options, freq);
    FitAmplitudeRef = SineCurveRef(1);
    FitPhaseRef = mod(SineCurveRef(2), 2*pi);

    PhaseShift = FitPhase - FitPhaseRef;

    figure(1); clf;
    subplot(2,1,1)
    plot(TimeProc, DataProc, 'r.'); hold on
    plot(TimeProc,SineFit(SineCurve,TimeProc,freq), 'k-');
    xlabel('aika (s)');
    ylabel('j‰nnite (V)');
    title(['V = ', num2str(FitAmplitude), ' V, \phi = ', num2str(FitPhase)]);
    grid on

    subplot(2,1,2)
    plot(TimeProc, DataRef, 'r.'); hold on
    plot(TimeProc,SineFit(SineCurveRef,TimeProc,freq), 'k-');
    xlabel('aika (s)');
    ylabel('j‰nnite (V)');
    title(['V_r_e_f = ', num2str(FitAmplitudeRef), ' V, \phi_r_e_f = ', num2str(FitPhaseRef), ', \Delta\phi = ', num2str(PhaseShift)]);
    grid on
    
    figure
    plot(TimeVector(1:SteadyState), DataIn(1:SteadyState))

    G = FitAmplitude / FitAmplitudeRef;
    delete(AI)
    clear AI

    delete(AO)
    clear AO
end