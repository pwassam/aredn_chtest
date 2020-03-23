import json
from pprint import pprint
from pathlib import Path
import numpy as np
from collections import defaultdict

from typing import List, Iterable

from matplotlib.backends.backend_pdf import PdfPages
from matplotlib.pylab import plt, Axes


def uniq(x: Iterable) -> List:
    return list(set(x))

def loadjson(f: Path) -> json:
    return json.load(open(f, 'rb'))

def extract_summary(f: Path) -> dict:
    """
    Extract bps, packet count sums from a result json
    :param j:
    :return:
    """
    j = loadjson(f)

    return dict(bps=j['end']['sum']['bits_per_second'],
                packets=j['end']['sum']['packets'],
                loss=j['end']['sum']['lost_packets'])

# Key constants
K_BPS = 0
K_PACKETS = 1
K_LOSS = 2

K_R1 = 0
K_R2 = 1
K_EXP = 2
K_SPEED = 3

def parse_fname(s: Path) -> (str, str, str, int):
    """
    Extract the filename paramaters from a path
    :param s:
    :return:
    """
    x = s.stem.split('_')
    return x[K_R1], x[K_R2], x[K_EXP], int(x[K_SPEED])

def parse_experiment(flist: List[Path]) -> (np.ndarray, List, List):
    """
    Given a list of input files, build a np matrix whose axes are:
        radio1, radio2, speed, param
    Indexes names into the array are returned
    :param flist: List of paths of input json files
    :return: Result matrix, Radio index names, Speed index names
    """

    # Extract radio names
    radios = [ parse_fname(f)[K_R1] for f in flist ] + \
             [ parse_fname(f)[K_R2] for f in flist ]
    radios = uniq(radios)
    radios.sort()

    # Extract speeds
    speeds = [ parse_fname(f)[K_SPEED] for f in flist ]
    speeds = [ x for x in speeds if x is not None ]
    speeds = uniq(speeds)
    speeds.sort()

    # Build result matrix
    # Radio Src, Radio Dst, Speed, Param(bps, packets, packet loss)
    m = np.full((len(radios), len(radios), len(speeds), 3), np.nan)

    # Populate matrix
    for f in flist:
        r1, r2, exp, speed = parse_fname(f)
        r1 = radios.index(r1)
        r2 = radios.index(r2)
        speed = speeds.index(speed)

        s = extract_summary(f)
        m[r1,r2,speed,K_BPS] = s['bps']
        m[r1,r2,speed,K_PACKETS] = s['packets']
        m[r1,r2,speed,K_LOSS] = s['loss']

    return m, radios, speeds

def plot_experiment(m: np.ndarray, radios: List[str], speeds: List[int], pdf: PdfPages, title: str=None):
    """
    Render a plot of an experiment matrix
    :param m:
    :param radios:
    :param speeds:
    :param pdf:
    :param title:
    :return:
    """
    # Assuming 2x2 radios only for now

    fig = plt.figure(figsize=(10.5, 7))
    gs = fig.add_gridspec(3,2)
    singlepoint = len(speeds) == 1

    if title:
        fig.suptitle("Experiment: %s" % title)

    # Baseline plots have a single point, and we dont plot cumulative for them
    if not singlepoint:
        ax = fig.add_subplot(gs[2,:])
        ax.set_title('Cumative')
        ax.set_ylabel('Acheived speed [mbps]')
        ax.set_xlabel('Attempted speed [mbps]')
        ax.grid(True)
        ax2 = ax.twinx()
        ax2.set_ylabel('Packet loss [%]')

        s = np.sum(m, axis=(0,1), where=~np.isnan(m))
        ax.plot(speeds, s[:,K_BPS]/1e6)
        ax2.set_ylabel('Packet loss [%]')
        err = s[:,K_LOSS] / s[:,K_PACKETS]
        ax2.plot(speeds, err, color='r')
        ax2.set_ylim([-1.0, max(err) + 1.0])

    # Determine the highest achieved speed so we can scale y axes the same
    ymax = (np.nanmax(m[:, :, :, K_BPS]) / 1e6) + 1.0

    for r1, r2, subp in [
        # Map of src radio, dst radio -> subplot coordinate
        [0, 1, [0, 0]], # A -> B upper left plot
        [1, 0, [0, 1]], # B -> A upper right plot
        [2, 3, [1, 0]], # C -> D lower left plot
        [3, 2, [1, 1]], # D -> C lower right plot
    ]:
        ax = fig.add_subplot(gs[subp[0],subp[1]])
        ax.set_title('%s -> %s' % (radios[r1], radios[r2]))
        ax.set_ylabel('Achieved speed [mbps]')
        ax.set_xlabel('Attempted speed [mbps]')
        ax.grid(True)
        ax.set_ylim([0.0, ymax])

        err = m[r1,r2,:,K_LOSS] / m[r1,r2,:,K_PACKETS]
        mbps = m[r1,r2,:,K_BPS] / 1e6

        # Baseline plots have a single point, just draw the line
        if singlepoint:
            ax.axhline(mbps[0])
        else:
            ax.plot(speeds, mbps)
            ax2 = ax.twinx()
            ax2.set_ylabel('Packet loss [%]')
            ax2.plot(speeds, err, color='r')
            ax2.set_ylim([-1.0, max(err) + 1.0])

    fig.tight_layout(rect=[0, 0.03, 1, 0.95])
    pdf.savefig(fig)

