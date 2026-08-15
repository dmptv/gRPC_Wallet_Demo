pipeline {
    // Xcode only runs on macOS, so the agent has to be a real Mac —
    // this is exactly the constraint we discussed: no macOS agent,
    // no iOS build, no matter which CI product sits on top of it.
    agent { label 'macos' }

    options {
        // Fail fast if a build ever hangs — real teams get bitten by
        // this once and add it forever after.
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {
        stage('Test') {
            steps {
                // WalletKit's own test suite — fast, no simulator boot
                // needed for the package tests we have today.
                sh 'bundle exec fastlane ios test'
            }
        }

        stage('Build') {
            steps {
                // No signing here on purpose: PR/branch builds only need
                // to prove the app compiles. Signing + TestFlight upload
                // is a separate stage, gated to the main branch only —
                // see the 'Release' stage below.
                sh 'bundle exec fastlane ios build_simulator'
            }
        }

        stage('Release') {
            when {
                branch 'main'
            }
            steps {
                // This is where fastlane match would come in: pull the
                // encrypted distribution certificate + provisioning
                // profile from the private match git repo, sign the
                // archive, then upload to TestFlight.
                //
                // Not run here — no paid Apple Developer account wired
                // up in this demo — but this is the real shape of it:
                //   sh 'bundle exec fastlane ios release'
                echo 'Release stage — would run fastlane match + upload here'
            }
        }
    }

    post {
        always {
            // dSYM + build log get archived on every run, not just
            // releases — this is the thing that's easy to forget and
            // expensive to regret, per our earlier dSYM discussion.
            archiveArtifacts artifacts: '**/*.log', allowEmptyArchive: true
        }
    }
}
