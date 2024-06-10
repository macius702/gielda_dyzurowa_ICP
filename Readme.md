# gielda_dyzurowa_ICP Project

## Prerequisites

- Git
- Docker

## Instructions

1. **Clone the repository**

    Use the following command to clone the repository:

    ```bash
    git clone git@github.com:macius702/gielda_dyzurowa_ICP.git
    ```

2. **Navigate into the project directory**

    Use the following command to navigate into the cloned repository:

    ```bash
    cd gielda_dyzurowa_ICP
    ```

3. **Build and run the Docker image**

    Use the following command to build the Docker image and run it in interactive mode:

    ```bash
    ./build_and_run.sh
    ```
    You can then go to another terminal and run tests with:
    ```
    ./test.sh from_backend.json
    ```
    This command will run the tests using the data from `from_backend.json`.

4. **Or build, run and test in one go**

    ```
    ./build_and_run.sh test
    ```
    This command will build the Docker image, run it in detached mode, and then run the tests.

## Useful commands

For Docker, you can run the following command:

```bash
command="curl -X POST -H \"Content-Type: application/json\" -d \"{ \\\"hello\\\": \\\"world\\\" }\" \"http://$(dfx canister id d_backend).localhost:$(dfx info webserver-port)\"" ; echo $command
```

After running this command in the Docker terminal, you can copy the output and paste it into the host's terminal to execute it.

# TODO according to: https://docs.flutter.dev/cookbook/design/drawer



- [x] 2 app_tests.dart - > one for register hospital, one for doctor
- [x] Prepare body: widgets (forms - h0ome, register, show users) array 
- [x] Integrate into Drawer
- [x] Extract LoginForm
- [ ] use CommonAppBar 
- [ ] Back to one test
- [ ] and test for Login
- [ ] // Handle dismiss

# TODO others


- [ ] is router async - I mean no need to specifically guard the common data operations 
- [ ] @Query("canisterId") canisterId: String into headers


# Example of drawer
```
class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'My App',
            home: HomeScreen(),
        );
    }
}

class HomeScreen extends StatefulWidget {
    @override
    _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
    int _currentIndex = 0;

    final _screens = [
        Screen1(),
        Screen2(),
        Screen3(),
    ];

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text('Home')),
            drawer: Drawer(
                child: ListView(
                    children: <Widget>[
                        ListTile(
                            title: Text('Screen 1'),
                            onTap: () {
                                setState(() {
                                    _currentIndex = 0;
                                });
                                Navigator.pop(context);
                            },
                        ),
                        ListTile(
                            title: Text('Screen 2'),
                            onTap: () {
                                setState(() {
                                    _currentIndex = 1;
                                });
                                Navigator.pop(context);
                            },
                        ),
                        ListTile(
                            title: Text('Screen 3'),
                            onTap: () {
                                setState(() {
                                    _currentIndex = 2;
                                });
                                Navigator.pop(context);
                            },
                        ),
                    ],
                ),
            ),
            body: _screens[_currentIndex],
        );
    }
}

class Screen1 extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return Center(child: Text('Screen 1'));
    }
}

class Screen2 extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return Center(child: Text('Screen 2'));
    }
}

class Screen3 extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return Center(child: Text('Screen 3'));
    }
}

```