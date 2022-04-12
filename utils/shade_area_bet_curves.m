function[h] = shade_area_bet_curves(xo, c1, c2, col, opacity)
resample = 0;
if resample == 1
factor = 1;
x = xo(1):(xo(2) - xo(1))/factor:xo(length(xo));
c1 = resample(c1,xo, factor, 'linear');
c2 = resample(c2,xo, factor, 'linear');
x(length(x)) =[];
c2(length(c2)-factor)
c1(length(c1)-factor+1:length(c1)) =[];
c2(length(c2)-factor+1:length(c2)) =[];
c1(1:factor) = c1(factor+1);
c2(1:factor) = c2(factor+1);
else
    x=xo;
end


%h{1} = plot(x,c1,'Color', col, 'HandleVisibility', 'Off');
hold on 
%h{2} = plot(x,c2, 'Color', col, 'HandleVisibility', 'Off');

for i = 1:numel(x)-1
        offspre = (x(2) - x(1))/2;
        offspost = (x(2) - x(1))/2;
      if i == 1
          offspre = x(2) - x(1);

      end
      if ~isnan(c1(i)) & ~isnan(c2(i))
          if c1(i) < c2(i)
              x1 = [x(i) x(i+1) x(i+1) x(i)]; 
              y1 = [c1(i) c1(i+1) c2(i+1) c2(i)];
              r{i} = patch(x1, y1, 'w', 'HandleVisibility', 'off');
          elseif c1(i) >= c2(i)
              x1 = [x(i) x(i+1) x(i+1) x(i)]; 
              y1 = [c2(i) c2(i+1) c1(i+1) c1(i)];
              r{i} = patch(x1, y1, 'w', 'HandleVisibility', 'off');
          end
          set(r{i},'FaceAlpha',opacity);
          r{i}.FaceColor = col;
          r{i}.LineStyle = 'none';
      end
end
    