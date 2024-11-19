classdef Decay <handle
    properties
        delays
        gate
        images
        spectra
        spectra_Bands
        spectra_Bands_norm
        CW
        tri_fit
        tri_fitopts
        tri_gof
        tri_curve
        bi_fit
        bi_fitopts
        bi_gof
        bi_curve
    end

    methods
        function decay = Decay()
            decay.delays=[];
            decay.images=Image.empty;
            decay.spectra=[];
            decay.spectra_Bands=[];
            decay.CW=[];
            decay.tri_fitopts=fitoptions( 'Method', 'NonlinearLeastSquares' );
            decay.tri_fitopts.Display = 'Off';
            decay.tri_fitopts.TolFun = 1e-07;
            decay.tri_fitopts.TolX = 1e-07;
            decay.bi_fitopts=fitoptions( 'Method', 'NonlinearLeastSquares' );
            decay.bi_fitopts.Display = 'Off';
            decay.bi_fitopts.TolFun = 1e-07;
            decay.bi_fitopts.TolX = 1e-07;
        end
        
        function addImage(self, image)
            self.delays=[self.delays; image.delay];
            self.images=[self.images; image];
            self.spectra=[self.spectra; image.spectrum_bin8];
            self.spectra_Bands=[self.spectra_Bands; image.spectrum_banded];
            if isempty(self.CW)
                self.CW=image.spectrum_bin8;
            end
            self.CW = self.CW + image.spectrum_bin8;
            [self.tri_fit, self.bi_fit] = deal(cell(1, size(self.spectra_Bands,2)));
            [self.tri_gof, self.bi_gof] = deal(struct( 'sse', cell(1,size(self.spectra_Bands,2)), 'rsquare', [], 'dfe', [], 'adjrsquare', [], 'rmse', []));
        end

        function addBands(self, bands)
            for k=1:size(self.spectra,1)
                for j=1:size(bands,2)/2
                    self.spectra_Bands(k,j)=sum(self.spectra(k,bands(j*2-1):bands(j*2)));
                end
                self.spectra_Bands(all(~self.spectra_Bands(k,:),1))=[];
            end
            [self.tri_fit, self.bi_fit] = deal(cell(1, size(self.spectra_Bands,2)));
            [self.tri_gof, self.bi_gof] = deal(struct( 'sse', cell(1,size(self.spectra_Bands,2)), 'rsquare', [], 'dfe', [], 'adjrsquare', [], 'rmse', []));
        end

        function normalise(self, normalisation_point)
            self.spectra_Bands_norm=self.spectra_Bands./self.spectra_Bands(normalisation_point,:);
        end
    end
    methods(Static)
        function [fitted, gof, curve, opts]= createTriFit(decay, zero_point)
            delays_shifted=decay.delays-zero_point;
            exclusion_points=find(delays_shifted<0);
            fitted = cell(1, size(decay.spectra_Bands,2));
            gof = struct( 'sse', cell(1,size(decay.spectra_Bands,2)), 'rsquare', [], 'dfe', [], 'adjrsquare', [], 'rmse', []);
            curve = zeros(size(delays_shifted,1),size(decay.spectra_Bands,2));
            decay.tri_fitopts.Exclude = exclusion_points;
            ft = fittype("A1*tau1*exp(-(x)/tau1)*(1-exp(-"+decay.gate+"/tau1))+A2*tau2*exp(-(x)/tau2)*(1-exp(-"+decay.gate+"/tau2))+A3*tau3*exp(-(x)/tau3)*(1-exp(-"+decay.gate+"/tau3))+offset", ...
                'independent', 'x', 'dependent', 'y' );
            for s=1:size(decay.spectra_Bands_norm,2)
                if isempty(decay.tri_fitopts.Lower)
                    decay.tri_fitopts.Weights = 1./decay.spectra_Bands_norm(:,s)';
                    if decay.gate>10
                        decay.tri_fitopts.Lower = [0 0 0 decay.spectra_Bands_norm(end,s)/100000 0.8 0.8 2];
                        decay.tri_fitopts.StartPoint = [0.5 0.1 0.01 decay.spectra_Bands_norm(end,s)/100 40 200 400];
                        decay.tri_fitopts.Upper = [1 1 1 0.1 100 500 3000];
                    else
    %                 [fitted{1,s}, gof(s)]=fit(delays_shifted,self.spectra_Bands_norm(:,s), ft, 'Method', 'NonlinearLeastSquares', ...
    %                                           'Algorithm', 'Trust-Region', 'Display', 'Off', 'MaxFunEvals', 600, ...
    %                                           'MaxIter', 400, 'TolFun', 1e-07, 'TolX', 1e-07, 'Exclude', exclusion_points, ...
    %                                           'Weights', 1./self.spectra_Bands_norm(:,s), 'Lower', [0 0 0 self.spectra_Bands_norm(end,s)/100000 0.8 0.8 2], ...
    %                                           'StartPoint', [0.5 0.1 0.01 self.spectra_Bands_norm(end,s)/100 40 200 400], ...
    %                                           'Upper', [1 1 1 0.1 100 500 3000]);
                        decay.tri_fitopts.Lower = [0 0 0 decay.spectra_Bands_norm(end,s)/100000 0.8 0.8 2];
                        decay.tri_fitopts.StartPoint = [0.5 0.1 0.01 decay.spectra_Bands_norm(end,s)/100 2 10 100];
                        decay.tri_fitopts.Upper = [1 1 1 0.1 50 100 1000];                        
                    end
                end
                try
                    [fitted{1,s}, gof(s)]=fit(delays_shifted,decay.spectra_Bands_norm(:,s), ft, decay.tri_fitopts);
                    curve(:,s)=fitted{s}.A1*fitted{s}.tau1*exp(-(delays_shifted)/fitted{s}.tau1)*(1-exp(-decay.gate/fitted{s}.tau1))+...
                           fitted{s}.A2*fitted{s}.tau2*exp(-(delays_shifted)/fitted{s}.tau2)*(1-exp(-decay.gate/fitted{s}.tau2))+...
                           fitted{s}.A3*fitted{s}.tau3*exp(-(delays_shifted)/fitted{s}.tau3)*(1-exp(-decay.gate/fitted{s}.tau3))+...
                           fitted{s}.offset;
                catch
                    fitted{s}=struct( 'A1', 0, 'A2', 0, 'A3', 0, 'offset', 0, 'tau1', 0, 'tau2', 0, 'tau3', 0);
                    gof(s)=struct( 'sse', 0, 'rsquare', 0, 'dfe', 0, 'adjrsquare', 0, 'rmse', 0);
                    curve(:,s)=0;
                end
            end
            opts{1,1}=decay.tri_fitopts.Lower;
            opts{1,2}=decay.tri_fitopts.StartPoint;
            opts{1,3}=decay.tri_fitopts.Upper;
        end

        function [fitted, gof, curve, opts]= createBiFit(decay, zero_point)
            delays_shifted=decay.delays-zero_point;
            exclusion_points=find(delays_shifted<0);
            fitted = cell(1, size(decay.spectra_Bands,2));
            gof = struct( 'sse', cell(1,size(decay.spectra_Bands,2)), 'rsquare', [], 'dfe', [], 'adjrsquare', [], 'rmse', []);
            curve = zeros(size(delays_shifted,1),size(decay.spectra_Bands,2));
            decay.bi_fitopts.Exclude = exclusion_points;
            ft = fittype("A1*tau1*exp(-(x)/tau1)*(1-exp(-"+decay.gate+"/tau1))+A2*tau2*exp(-(x)/tau2)*(1-exp(-"+decay.gate+"/tau2))+offset", ...
                'independent', 'x', 'dependent', 'y' );
            for s=1:size(decay.spectra_Bands_norm,2)
                if isempty(decay.bi_fitopts.Lower)
                    decay.bi_fitopts.Weights = 1./decay.spectra_Bands_norm(:,s)';
                        if decay.gate>10
                            decay.bi_fitopts.Lower = [0 0 decay.spectra_Bands_norm(end,s)/100000 0.8 2];
                            decay.bi_fitopts.StartPoint = [0.5 0.1 decay.spectra_Bands_norm(end,s)/100 40 400];
                            decay.bi_fitopts.Upper = [1 1 0.1 500 3000];
                        else
                            decay.bi_fitopts.Lower = [0 0 decay.spectra_Bands_norm(end,s)/100000 0.8 2 ];
                            decay.bi_fitopts.StartPoint = [0.5 0.1 decay.spectra_Bands_norm(end,s)/100 20 50];
                            decay.bi_fitopts.Upper = [1 1 0.1 50 1000];
                        end
                end
                try
                    [fitted{1,s}, gof(s)]=fit(delays_shifted,decay.spectra_Bands_norm(:,s), ft, decay.bi_fitopts);
                    curve(:,s)=fitted{s}.A1*fitted{s}.tau1*exp(-(delays_shifted)/fitted{s}.tau1)*(1-exp(-decay.gate/fitted{s}.tau1))+...
                               fitted{s}.A2*fitted{s}.tau2*exp(-(delays_shifted)/fitted{s}.tau2)*(1-exp(-decay.gate/fitted{s}.tau2))+...
                               fitted{s}.offset;
                catch
                    fitted{s}=struct( 'A1', 0, 'A2', 0, 'offset', 0, 'tau1', 0, 'tau2', 0);
                    gof(s)=struct( 'sse', 0, 'rsquare', 0, 'dfe', 0, 'adjrsquare', 0, 'rmse', 0);
                    curve(:,s)=0;
                end
            end
            opts{1,1}=decay.bi_fitopts.Lower;
            opts{1,2}=decay.bi_fitopts.StartPoint;
            opts{1,3}=decay.bi_fitopts.Upper;
        end

        function decay_list = applyTriFit(decay_list, fitted, gof, curve)
            for i=1:size(decay_list,1)
                decay_list{i}.tri_fit=fitted{i};
                decay_list{i}.tri_gof=gof{i};
                decay_list{i}.tri_curve=curve{i};
            end
        end

        function decay_list = applyBiFit(decay_list, fitted, gof, curve)
            for i=1:size(decay_list,1)
                decay_list{i}.bi_fit=fitted{i};
                decay_list{i}.bi_gof=gof{i};
                decay_list{i}.bi_curve=curve{i};
            end
        end

        function applyOpts(decay_list, tri, bi)
            for i=1:size(decay_list,1)
                decay_list{i}.tri_fitopts.Lower=tri{i}{1};
                decay_list{i}.tri_fitopts.StartPoint=tri{i}{2};
                decay_list{i}.tri_fitopts.Upper=tri{i}{3};
                decay_list{i}.bi_fitopts.Lower=bi{i}{1};
                decay_list{i}.bi_fitopts.StartPoint=bi{i}{2};
                decay_list{i}.bi_fitopts.Upper=bi{i}{3};
            end
        end

    end
end