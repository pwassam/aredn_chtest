from chtest_analysis import *

flist = list(Path(r'chtest_20200322/data').glob('*.json'))
if not len(flist):
    raise RuntimeError("No files")

# Build list of per-experiment files
experiment_flist = defaultdict(list)
for f in flist:
    experiment_flist[parse_fname(f)[K_EXP]].append(f)

print("Experiments:")
pprint(list(experiment_flist.keys()))

experiments = {}
for exp, flist in experiment_flist.items():
    experiments[exp] = parse_experiment(flist)

exptitles = {
    'baseline': 'Baseline performance',
    'common': 'Shared channel 184',
    '184-183': 'Mixed channels 184, 183',
    '184-182': 'Mixed channels 184, 182',
    '184-181': 'Mixed channels 184, 181',
    '184-180': 'Mixed channels 184, 180',
}

with PdfPages('chtest_analysis_20200322.pdf') as pdf:
    for exp, title in exptitles.items():
        print("Processing", exp)
        plot_experiment(*experiments[exp], title=title, pdf=pdf)

print("DONE")