"""Compare isolated package action timings; invoke through tools/test-in-container.sh.

Example: run python tools/benchmark-package-actions.py --candidate baseline=/repo/private/before.sh --candidate batching=/repo/usb/lib/packages.sh
The baseline helper must be copied from the baseline commit before starting the container.
"""
import argparse, json, os, statistics, subprocess, sys
from pathlib import Path

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--candidate',action='append',required=True,metavar='LABEL=HELPER')
parser.add_argument('--runs',type=int,default=5)
args=parser.parse_args()
if args.runs<5:parser.error('Use at least five measured runs.')
root=Path(__file__).resolve().parents[1]
results={}
# Alternate candidate order to reduce cache/order bias. Round zero is warm-up.
for round_ in range(args.runs+1):
 for candidate in (args.candidate if round_%2==0 else list(reversed(args.candidate))):
  label,helper=candidate.split('=',1)
  env=dict(os.environ,MZD_BENCHMARK_HELPER=str(Path(helper).resolve()))
  result=subprocess.run([sys.executable,str(root/'tests/contract/test_gui_extensions.py'),'--performance-only'],env=env,capture_output=True,text=True,timeout=3600)
  if result.returncode:raise RuntimeError(result.stdout+result.stderr)
  rows=json.loads(next(line.partition('=')[2] for line in result.stdout.splitlines() if line.startswith('PACKAGE_PERFORMANCE=')))
  print(json.dumps({'candidate':label,'round':round_,'warmup':round_==0,'actions':rows}),flush=True)
  if round_:results.setdefault(label,[]).append(rows)
summary={}
for label,runs in results.items():
 actions=[]
 for index,row in enumerate(runs[0]):
  actions.append({'action':row['action'],'median_seconds':statistics.median(run[index]['seconds'] for run in runs),'median_pid_delta':statistics.median(run[index]['pid_delta'] for run in runs)})
 summary[label]={'actions':actions,'median_total_seconds':statistics.median(sum(row['seconds'] for row in run) for run in runs),'median_total_pid_delta':statistics.median(sum(row['pid_delta'] for row in run) for run in runs)}
baseline=summary[args.candidate[0].split('=',1)[0]]
for label,data in summary.items():
 data['total_time_reduction_percent']=100*(baseline['median_total_seconds']-data['median_total_seconds'])/baseline['median_total_seconds']
 data['total_pid_reduction_percent']=100*(baseline['median_total_pid_delta']-data['median_total_pid_delta'])/baseline['median_total_pid_delta']
 for reference,row in zip(baseline['actions'],data['actions']):
  row['time_reduction_percent']=100*(reference['median_seconds']-row['median_seconds'])/reference['median_seconds']
  row['pid_reduction_percent']=100*(reference['median_pid_delta']-row['median_pid_delta'])/reference['median_pid_delta']
print('PACKAGE_PERFORMANCE_SUMMARY='+json.dumps(summary,sort_keys=True),flush=True)
