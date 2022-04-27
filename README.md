# Facebook Flow Mac M1 Binary Build

To Build Flow on a M1 Mac, you need to:

1. Clone flow with `git clone git@github.com:facebook/flow.git && cd flow`
2. Create a bin folder with `mkdir bin && cd bin`
3. Clone (or fork and clone) [this repo](https://github.com/sfeuga/flow-bin-m1) with `git clone git@github.com:sfeuga/flow-bin-m1.git .`
4. Optional: If you fork it and want to release it in your repo, create a GitHub Repo Access token (need read/write on the repo) and Create a `.env` file with your GitHub Repo Access token, your GitHub username and your repo name
5. Install [asdf-vm](https://asdf-vm.com/guide/getting-started.html)
6. Run `./build.sh`
7. Wait and you'll get the result in your current (`bin`) folder (`flow` and `flow.js`).
