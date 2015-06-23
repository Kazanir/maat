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

    $http = Map {};
    foreach ($comb as $key => $value) {
      $code = substr($key, 6, 3);
      if (substr($key, 0, 5) == "Nginx" && is_numeric($code)) {
        $http[$code] = $value;
      }
    }
    $r["responses"] = $http;

    post_results($r);
  }
}

function post_results(Map<string, mixed> $result): void {
  syslog(LOG_INFO,print_r($result, TRUE));
}
