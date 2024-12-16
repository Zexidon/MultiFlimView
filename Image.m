classdef Image <handle
    properties
        delay
        gate
        gain
        xbin
        ybin
        CCD_ExpTime
        data
        dataCorrected
        spectrum_bin8
        spectrum_corr
        spectrum_norm
        spectrum_corr_norm
        spectrum_banded
        indexes
    end

    methods
        function image = Image(delay, gate, gain, xbin, ybin, CCD_ExpTime, data, dataCorrected)
            % if delay == -100
            %     delay = 100500;
            % end
            image.delay=delay;
            image.gate=gate;
            image.gain=gain;
            image.xbin=xbin;
            image.ybin=ybin;
            image.CCD_ExpTime=CCD_ExpTime;
            image.data=data;
            image.dataCorrected=dataCorrected;
            spectrum=sum(image.dataCorrected);
            if image.xbin<=8
                image.spectrum_bin8=sum(reshape(spectrum,(2688/image.xbin)/336,336),1);
            else
                image.spectrum_bin8=interp1(2:2:size(spectrum,2)*2,spectrum,1:336)./(8./image.xbin);
            end
            image.spectrum_norm = image.spectrum_bin8./max(image.spectrum_bin8,[],"all");
            image.indexes = [1 size(data,1)];
        end
        
        function efficiency(self, efficiency)
            self.spectrum_corr = self.spectrum_bin8./efficiency;
            self.spectrum_corr_norm = self.spectrum_corr./max(self.spectrum_corr,[],"all");
        end

        function addBands(self, bands)
            for j=1:size(bands,2)/2
                self.spectrum_banded(1,j)=sum(self.spectrum_corr(bands(j*2-1):bands(j*2)));
                self.spectrum_banded(all(~self.spectrum_banded(1,j),1))=[];
            end
        end

        function yCrop(self, y1, y2, efficiency)
            spectrum=sum(self.dataCorrected(y1:y2,:));
            if self.xbin<=8
                self.spectrum_bin8=sum(reshape(spectrum,(2688/self.xbin)/336,336),1);
            else
                self.spectrum_bin8=interp1(2:2:size(spectrum,2)*2,spectrum,1:336)./(8./self.xbin);
            end
            self.spectrum_norm = self.spectrum_bin8./max(self.spectrum_bin8,[],"all");
            self.spectrum_corr = self.spectrum_bin8./efficiency;
            self.spectrum_corr_norm = self.spectrum_corr./max(self.spectrum_corr,[],"all");
        end

    end

    methods (Static)
        % Load .imh (Hamatsu) files and display the image corrected for Gain and Exp_time
        function image = loadimh(FileName)
            % Constants
            GHam = [599 600 620 640 660 680 700 720 740 760 780 800 820 840 860 880 900 920 940 960 980 999];
            HHam = [1 1.00 1.34 1.88 2.55 3.49 4.78 6.42 8.65 11.56 15.60 20.72 27.16 35.43 46.73 60.41 78.18 100.61 128.61 162.51 209.73 258.58]/258.58;
            IML_HEADER_LENGTH=1280;
            % Read the Image File
            fid = fopen(FileName,'r','ieee-le');
            delay = fscanf(fid,'%12f',1);
            gate = fscanf(fid,'%12f',1);
            gain = fscanf(fid,'%12f',1);
            xbin = fscanf(fid,'%4d',1);
            ybin = fscanf(fid,'%4d',1);
            rowLength = fscanf(fid,'%8d',1);
            colLength = fscanf(fid,'%8d',1);
            sizeUtil = (rowLength*colLength);
            CCD_ExpTime=fscanf(fid,'%12f',1);
            % skip the header padding
            fseek(fid,IML_HEADER_LENGTH,-1);
            fileSize = getfield(dir(FileName),'bytes');
            if (fileSize~=sizeUtil*2+IML_HEADER_LENGTH) 
                ErrorStr = ['File ' FileName ' has wrong size'];
                errordlg(ErrorStr,'File Error');
                return
            end
            % Read the image
            [Imagedata] = fread(fid,sizeUtil,'uint16');
            fclose(fid);
            data=reshape(Imagedata,rowLength,colLength)';
            gainHam = 1./exp(interp1(GHam,log(HHam),gain));
            dataCorrected=data*gainHam/CCD_ExpTime;
            image = Image(delay, gate, gain, xbin, ybin, CCD_ExpTime, data, dataCorrected);
        end
    end
   
end