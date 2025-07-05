# Import the oxalica rust overlay directly
import (builtins.fetchTarball {
  url = "https://github.com/oxalica/rust-overlay/archive/master.tar.gz";
  sha256 = "sha256-dYO5X5jK8bpQOeRAo8R5aUt6M/+Ji1cZgstZI7SQ2IA=";
})
