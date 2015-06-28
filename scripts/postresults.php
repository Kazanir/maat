<?hh

run();

function run(): void {
  foreach (scandir(results_dir()) as $file) {
    if ($file != "." && $file != "..") {
      process_results_file($file);
    }
  }
}

<<__Memoize>>
function commit_hash(): string {
  return getenv("D8_ACTUAL_COMMIT");
}

<<__Memoize>>
function commit_time(): int {
  return (int) getenv("D8_COMMIT_TIME");
}

<<__Memoize>>
function results_dir(): string {
  return __DIR__ . '/../results/';
}

<<__Memoize>>
function infra_tag(): string {
  return getenv("MAAT_INFRASTRUCTURE_TAG");
}

<<__Memoize>>
function runtime_labels(): Map<string, string> {
  $labels = Map {
    "php5" => "PHP 5.6.9",
    "php7" => "PHP 7 (2015-05-24)",
    "hhvm" => "HHVM 3.7.2 Repo.Auth",
  };

  return $labels;
}

function get_concurrency(string $filepath): string {
  $stuff = explode('_', $filepath);
  $c = substr($stuff[1], 1);

  return $c;
}

function process_results_file(string $filepath): void {
  $json = file_get_contents(results_dir() . $filepath);
  $concurrency = get_concurrency($filepath);
  $results = json_decode($json, TRUE);
  if (!$results) {
    return;
  }
  foreach ($results as $target => $runtimes) {
    process_target($target, $concurrency, $runtimes);
  }
}

function process_target(string $target, string $concurrency, array $runtimes): void {
  $labels = runtime_labels();

  foreach ($runtimes as $runtime => $results) {
    $comb = $results['Combined'];
    $r = Map {};
    $r["infra"] = infra_tag();
    $r["rps"] = $comb["Siege RPS"];
    $r["requests"] = $comb["Siege requests"];
    $r["requests_success"] = $comb["Siege successful requests"];
    $r["requests_failed"] = $comb["Siege failed requests"];
    $r["nginx_hits"] = $comb["Nginx hits"];
    $r["bytes"] = $comb["Nginx avg bytes"];
    $r["time"] = (string) round($comb["Nginx avg time"] * 1000, 4);
    $r["target"] = $target;
    $r["runtime"] = $runtime;
    $r["runtime_label"] = $labels[$runtime];
    $r["commit"] = commit_hash();
    $r["commit_time"] = commit_time();
    $r["concurrency"] = $concurrency;

    $r["raw"] = $comb;
    handle_results($r);
  }
}

function handle_results(Map<string, mixed> $result): void {
  $endpoint = getenv("MAAT_RESULTS_ENDPOINT");
  if ($endpoint) {
    post_results($endpoint, $result);
  }
  else {
    syslog(LOG_INFO, json_encode($result));
  }
}

function post_results(string $endpoint, Map<string, mixed> $result) {
  $data = json_encode($result);

  $ch = curl_init($endpoint);
  curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "POST");
  curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
  curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Content-Length: ' . strlen($data),
  ]);

  $response = curl_exec($ch);
}
