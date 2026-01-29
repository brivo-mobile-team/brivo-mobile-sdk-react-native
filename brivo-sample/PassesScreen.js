import React, { Component } from 'react';
import { SectionList, StyleSheet, Text, TouchableOpacity, View, NativeModules, ActivityIndicator } from 'react-native';
import { NativeEventEmitter } from 'react-native';

const BrivoSDK = NativeModules.BrivoSDKModule
const brivoEventEmitter = new NativeEventEmitter(BrivoSDK);

export default class PassesScreen extends Component {
    constructor(props) {
        super(props);
        this.state = {
            isLoading: true,
            sdkVersion: "",
            dataSource: []
        };
    }

    retrieveData = () => {
        BrivoSDK.retrieveSDKLocallyStoredPasses()
            .then(result => {
                if (result) {
                    passesJson = JSON.parse(result)
                } else {
                    passesJson = []
                }
                this.setState({
                    dataSource: passesJson
                });
                this.refreshData()
            })
            .catch((error) => {
                alert(error)
                this.setState({
                    ...this.state, isLoading: false
                })
            });
            this.getVersion()

    };

    getVersion = () => {
        BrivoSDK.getVersion()
        .then(result => {
            this.setState({
                sdkVersion : result
            })
        })
    }

    refreshData = () => {
        const refreshPromises = this.state.dataSource.map((item, index) => {
            const brivoTokens = item.brivoOnairPassCredentials.tokens;
            const brivoTokenJSON = JSON.stringify(brivoTokens);
    
            return BrivoSDK.refreshPass(brivoTokenJSON)
                .then(response => {
                    const newData = [...this.state.dataSource];
                    newData[index] = JSON.parse(response);
                    this.setState({ dataSource: newData });
                })
                .catch(error => {
                    console.error("Error refreshing pass for account:", item.accountName, error);
                });
        });
    
        Promise.all(refreshPromises)
            .then(() => {
                this.setState({ isLoading: false });
            });
    } 

    componentDidMount() {
        this.unlockAccessPointListener = brivoEventEmitter.addListener(
            'UnlockAccessPointUpdate',
            (data) => {
              console.log('UnlockAccessPointUpdate event received:', data);
              this.setState({ isLoading: false });
              if (data.error) {
                alert(`Error: ${data.error}`);
              } else {
                alert(`${data}`);
              }
            }
          );

          this.unlockNearestAccessPointListener = brivoEventEmitter.addListener(
            'UnlockNearestAccessPointUpdate',
            (data) => {
              console.log('UnlockNearestAccessPointUpdate event received:', data);

              this.setState({ isLoading: false });
              if (data.error) {
                alert(`Error: ${data.error}`);
              } else {
                alert(`${data}`);
              }
            }
          );
        this._unsubscribe = this.props.navigation.addListener('focus', () => {
            this.retrieveData()
        });
        BrivoSDK.init(JSON.stringify({
            "clientId": "<clientID>",
            "clientSecret": "<clientSecret>",
            "useSDKStorage": true,
            "useEuRegion": false,
        }))
            .then(result => {
                this.retrieveData()
            })
            .catch((error) => {
                alert(error)
            });
    }

    componentWillUnmount() {
        if (this.unlockAccessPointListener) {
            this.unlockAccessPointListener.remove();
          }
          if (this.unlockNearestAccessPointListener) {
            this.unlockNearestAccessPointListener.remove();
          }
        this._unsubscribe();
    }

    onUnlockMagicDoor = () => {
        this.setState({ isLoading: true });
        BrivoSDK.unlockNearestAccessPoint();
    }

    onAccessPointClicked = (item) => {
        this.setState({ isLoading: true });

        BrivoSDK.unlockAccessPoint(item.passId, item.id.toString());
      }

    render() {
        console.log("State ", this.state)
        let sections = []
        if (this.state.dataSource) {
            sections = this.state.dataSource.flatMap((item) =>{
                if(item && item.sites){
                    return item.sites.map((site) => {
                        return{
                            title: site.siteName,
                            data: site.accessPoints.map((accessPoint) => { return { ...accessPoint, passId: item.pass } })
                        }
                    })
                }
                return [];
            })
        }
        console.log("Sections ", sections)
        return (

            <View style={passesScreenStyles.container}>
                {!sections || sections.length === 0
                    ? <Text style={passesScreenStyles.noPassesText}>Please redeem a pass</Text>
                    :
                    <TouchableOpacity onPress={() => this.onUnlockMagicDoor()} style={passesScreenStyles.magicDoorBtn}>
                        <Text style={passesScreenStyles.redeemPassBtnText}>MAGIC DOOR</Text>
                    </TouchableOpacity>
                }
                <SectionList
                    sections={sections}
                    renderItem={({ item }) => <Text style={passesScreenStyles.item} onPress={() => this.onAccessPointClicked(item)} >{item.name}</Text>}
                    renderSectionHeader={({ section }) => <Text style={passesScreenStyles.sectionHeader}>{section.title}</Text>}
                    keyExtractor={(item, index) => index}
                />
                <TouchableOpacity onPress={() => this.props.navigation.navigate('RedeemPassScreen')} style={passesScreenStyles.redeemPassBtn}>
                    <Text style={passesScreenStyles.redeemPassBtnText}>ADD PASS</Text>
                </TouchableOpacity>
                <Text style={passesScreenStyles.versionText}>Version {this.state.sdkVersion}</Text>

                {this.state.isLoading &&
                    <View style={passesScreenStyles.loading}>
                        <ActivityIndicator size='large' color="#fb5b5a" />
                    </View>
                }
            </View>
        );
    }
}

const passesScreenStyles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: "#465881",
    },
    sectionHeader: {
        paddingTop: 2,
        paddingLeft: 10,
        paddingRight: 10,
        backgroundColor: '#003f5c',
        paddingBottom: 2,
        fontSize: 18,
        color: "#fb5b5a",
        fontWeight: 'bold',
    },
    item: {
        padding: 10,
        fontSize: 14,
        color: "white",
        height: 44,
    },
    redeemPassBtn: {
        width: "100%",
        backgroundColor: "#fb5b5a",
        height: 50,
        alignItems: "center",
        justifyContent: "center",
        marginTop: 10,
        marginBottom: 40
    },
    versionText:{
        width: "100%",
        height: 25,
        alignItems:"center",
        marginTop: 0,
        marginBottom: 0
    },
    magicDoorBtn: {
        width: "100%",
        backgroundColor: "#fb5b5a",
        height: 50,
        alignItems: "center",
        justifyContent: "center",
    },
    redeemPassBtnText: {
        color: "white"
    },
    noPassesText: {
        width: "100%",
        textAlign: 'center',
        color: "white",
        padding: 20,
        alignItems: "center",
        fontSize: 20,
    },
    loading: {
        position: 'absolute',
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
        alignItems: 'center',
        justifyContent: 'center'
    }
})     