function [positions, classification] = Classificate(rec)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % loading data
    
    record = strcat('data/', rec, 'm.mat');

    avg_record = strcat('data/avg', rec, '.txt');

    annot = strcat('data/', rec, '.txt');

    [annot_time, cnt] = readannotations(annot);
    
    positions = annot_time(:, 1);

    load(record);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % average NORMAL hearbeat in first 5 minutes - FP - 60 ms to FP + 100 ms
    % sigavg -r RECORD -a atr -f 0 -t 300 -p N -d -0.060 0.100 >avgRECORD.txt
    
    average_record = load(avg_record);
    
    % sometimes, there is no NORMAL hearbeat in first 5 minutes - handle
    % this exception
    
    try
        average_value = average_record(:, 2);
    catch

    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % process the signal with high-pass recursive filter for drift suppression
    
    fs = 360;

    ms = 1 / fs; 
    
    signal = val(1,:);

    signal = signal(:);
   
    norm_signal = HPFilter(signal, 2.2, ms);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % left window and right window
    
    left = round(0.06 * fs);

    right = round(0.10 * fs);

    first_norm = [];
    second_norm = [];
    infinity_norm = [];
    dissimilarity_norm = [];


    %test_nenormalen = [];
    %stevilo = 0;

    beats = annot_time(:, 2);
    
    %plot(signal(27000:36000), 'DisplayName','input signal'); hold on; plot(norm_signal(27000:36000), 'DisplayName','filtered signal'); lgd = legend();
    %lgd.FontSize = 15;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % main loop - comparing values with average beat and calculating norms.
    
    for i = 1 : cnt - 1
        
        % to handle the right end!
        right_border = annot_time(i) + right - 1;
        
        if (right_border > length(norm_signal))
            right_border = length(norm_signal);
        end
        
        % to check how many V beats are there
        %if (beats(i) == 1)
        %    test_nenormalen = [test_nenormalen, i];
        %    stevilo = stevilo + 1;
        %end

        % window arounnd FP
        signal_value = norm_signal(annot_time(i) - left + 1: right_border);

        N = length(signal_value);

        % turns out that the dissimilarity_norm is best
        
        %first_norm = [first_norm, sum(abs(signal_value - average_value)) / N];
        %second_norm = [second_norm, sqrt((sum((signal_value - average_value).^2) / N))];
        %infinity_norm = [infinity_norm, max(abs(signal_value - average_value))];

        Sx = sum((signal_value - mean(signal_value)).^2);
        Sy = sum((average_value - mean(average_value)).^2);

        r = (Sx * Sy)^(-1/2) * sum((signal_value - mean(signal_value)) * (average_value - mean(average_value)));

        if (r > 0)
            d_r = 1 - r;
        else
            d_r = 1;
        end
        % dissimilarity norm - 1 means that this is probably V beat. 
        dissimilarity_norm = [dissimilarity_norm, d_r];
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % calculating the threshold
 
    % first threshold - when difference of two consecutive norms orderded ascending 
    % is more than 1 standard deviation
    
    difference = dissimilarity_norm;

    difference_asc = sort(difference,'ascend');

    deviation = std(difference_asc);

    threshold1 = max(difference) + 1;

    for k = 1 : length(difference_asc) - 1
        if (-difference_asc(k) + difference_asc(k+1) >= deviation)
            threshold1 = difference_asc(k);
        else
            continue
        end
    end

    % second threshold - find the biggest gap in norms.

    biggest_diff = 0;
    
    threshold2 = 0;

    for k = 1 : length(difference_asc) - 1
        local_diff = difference_asc(k + 1)-difference_asc(k);
        if local_diff >= biggest_diff
            biggest_diff = local_diff;
            threshold2 = difference_asc(k);
        end
    end

    % comparing two norms
    
    %if (threshold1 == 2)
    %    threshold = threshold1;
    %else
    %    threshold = threshold2;
    %end

    threshold = min(threshold1, threshold2);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    classification = [];

    % we can set some fixed threshold, but the results are worse.
    for l = 1 : length(difference)
        if difference(l) >= threshold
            classification = [classification, 1];
        else
            classification = [classification, 0];
        end
    end
