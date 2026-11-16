#!/usr/bin/env python3
"""Plot actual Verilator VCD transitions; requires matplotlib.
Run: make waves SEED=42 N_RANDOM=0; python waveforms/plot_waveforms.py
"""
import argparse
import hashlib
import json
import re
from bisect import bisect_right
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt


def read_vcd(path):
    scopes, names, changes = [], {}, {}
    now, header, factor = 0, True, None
    units = {'s':1e9, 'ms':1e6, 'us':1e3, 'ns':1, 'ps':1e-3, 'fs':1e-6}
    for raw in path.read_text().splitlines():
        line=raw.strip()
        if header:
            if line.startswith('$timescale'):
                m=re.search(r'(\d+)\s*(fs|ps|ns|us|ms|s)',line)
                if not m: raise ValueError('Expected a one-line timescale')
                factor=int(m[1])*units[m[2]]
            elif line.startswith('$scope'): scopes.append(line.split()[2])
            elif line.startswith('$upscope'): scopes.pop()
            elif line.startswith('$var'):
                p=line.split(); names['.'.join(scopes+[p[4]])]=p[3]
                changes.setdefault(p[3],[])
            elif line.startswith('$enddefinitions'): header=False
            continue
        if not line or line.startswith('$'): continue
        if line.startswith('#'): now=int(line[1:])*factor; continue
        if line[0] in 'bB': value,code=line[1:].split()
        elif line[0] in '01xXzZ': value,code=line[0],line[1:]
        else: continue
        if code in changes:
            if any(c in value.lower() for c in 'xz'): raise ValueError('Four-state data requires explicit rendering')
            changes[code].append((now,int(value,2)))
    return {name:changes[code] for name,code in names.items()}


def value_at(events,time):
    i=bisect_right([t for t,_ in events],time)-1
    if i<0: raise ValueError('Missing value')
    return events[i][1]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('vcd',nargs='?',default='build/uart.vcd')
    parser.add_argument('output',nargs='?',default='waveforms')
    args=parser.parse_args()
    source,out=Path(args.vcd),Path(args.output); out.mkdir(parents=True,exist_ok=True)
    signals=read_vcd(source)
    bus={name:signals['tb_uart.bus.'+name] for name in
         ['tx','tx_start','tx_busy','tx_done','rx','rx_data','rx_valid','rx_error']}
    # uart_pkg uses 1 ns time units; VCD events above are converted to ns.
    bit_time=signals['uart_pkg.BIT_TIME'][0][1]
    def decode(line,start):
        return sum(value_at(bus[line],start+(1.5+i)*bit_time)<<i for i in range(8))
    tx_start=next(t for t,v in bus['tx_busy'] if v==1 and decode('tx',t)==0x55)
    rx_event=next(t for t,v in bus['rx_valid'] if v==1 and value_at(bus['rx_data'],t)==0x55)
    error_event=next(t for t,v in bus['rx_error'] if v==1)
    def find_start(event):
        return next(t for t,v in bus['rx'] if v==0 and event-10*bit_time<t<event-9*bit_time)
    rx_start,error_start=find_start(rx_event),find_start(error_event)
    assert decode('rx',rx_start)==0x55
    assert value_at(bus['rx'],error_start+9.5*bit_time)==0
    assert value_at(bus['rx_valid'],error_event)==0
    assert value_at(bus['rx_data'],error_event-1)==value_at(bus['rx_data'],error_event)
    records=[]
    def plot(filename,title,subtitle,start,line,tracks,event,label):
        left,right=start-.2*bit_time,start+11*bit_time
        fig,axes=plt.subplots(len(tracks)+1,1,figsize=(14,6.2),sharex=True,
                             gridspec_kw={'height_ratios':[.8]+[1]*len(tracks)})
        fig.patch.set_facecolor('#f8fafc')
        fig.suptitle(title,x=.135,y=.965,ha='left',fontsize=19,weight='bold',color='#0f172a')
        fig.text(.135,.906,subtitle,fontsize=10,color='#475569')
        for i,bit_label in enumerate(['START']+[f'D{i}' for i in range(8)]+['STOP']):
            x0,x1=(start+i*bit_time)/1000,(start+(i+1)*bit_time)/1000
            val=value_at(bus[line],start+(i+.5)*bit_time)
            color='#fee2e2' if bit_label=='STOP' and val==0 else '#e2e8f0'
            axes[0].axvspan(x0,x1,facecolor=color,edgecolor='white')
            axes[0].text((x0+x1)/2,.5,f'{bit_label}\n{val}',ha='center',va='center',fontsize=9)
        axes[0].set_ylim(0,1); axes[0].axis('off')
        for ax,name in zip(axes[1:],tracks):
            ax.set_facecolor('#f8fafc')
            pts=[(left,value_at(bus[name],left))]+[(t,v) for t,v in bus[name] if left<t<right]+[(right,value_at(bus[name],right))]
            if name=='rx_data':
                for (t,v),(end,_) in zip(pts,pts[1:]):
                    ax.fill_between([t/1000,end/1000],.18,.82,color='#dbeafe',edgecolor='#2563eb')
                    if end-t>bit_time*.25: ax.text((t+end)/2000,.5,f'0x{v:02X}',ha='center',va='center',fontsize=10,color='#1e40af')
                ax.set_yticks([])
            else:
                ax.step([t/1000 for t,_ in pts],[v for _,v in pts],where='post',lw=1.8,color='#dc2626' if name=='rx_error' else '#0284c7')
                ax.set_yticks([0,1]); ax.tick_params(axis='y',labelsize=8,length=0)
            ax.set_ylim(-.18,1.18)
            ax.set_ylabel(name,rotation=0,ha='right',va='center',labelpad=18,fontsize=10,weight='bold')
            for i in range(11): ax.axvline((start+i*bit_time)/1000,color='#cbd5e1',lw=.6,zorder=0)
            for spine in ax.spines.values(): spine.set_visible(False)
            ax.axvline(event/1000,color='#d97706',lw=.9,ls='--')
        target = 'tx_done' if line=='tx' else ('rx_error' if 'error' in label else 'rx_valid')
        axes[tracks.index(target)+1].annotate(label,xy=(event/1000,1),xytext=(event/1000-.30,.55),
                          arrowprops={'arrowstyle':'->','color':'#92400e'},fontsize=9,color='#92400e',ha='right')
        axes[-1].set_xlim(left/1000,right/1000); axes[-1].set_xlabel('Simulation time (µs)',fontsize=11)
        fig.text(.135,.025,'Source: actual Verilator VCD  •  100 MHz clock  •  160 ns per bit  •  8N1 / LSB first',fontsize=9,color='#64748b')
        fig.subplots_adjust(left=.135,right=.98,top=.86,bottom=.13,hspace=.23)
        fig.savefig(out/filename,dpi=160,facecolor=fig.get_facecolor()); plt.close(fig)
        records.append({'file':filename,'frame_start_ns':start,'decoded_byte':f'0x{decode(line,start):02X}','event_ns':event})
    done=next(t for t,v in bus['tx_done'] if v==1 and t>tx_start)
    plot('tx_55.png','UART transmission · 0x55','Alternating data bits are transmitted LSB first; busy spans the complete frame.',tx_start,'tx',['tx_start','tx','tx_busy','tx_done'],done,'done pulse')
    plot('rx_55.png','UART reception · 0x55','The received byte updates to 0x55 when the one-clock valid pulse is asserted.',rx_start,'rx',['rx','rx_data','rx_valid','rx_error'],rx_event,'valid pulse')
    plot('rx_framing_error.png','UART reception · invalid stop bit','A low stop bit raises framing_error; valid stays low and the last good byte is retained.',error_start,'rx',['rx','rx_data','rx_valid','rx_error'],error_event,'error pulse')
    (out/'trace_metadata.json').write_text(json.dumps({'vcd_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'time_unit':'ns','bit_time_ns':bit_time,'figures':records},indent=2)+'\n')
    print(json.dumps(records,indent=2))

if __name__=='__main__': main()
