import React, { Component } from 'react';
import { StyleSheet, Text, View, TextInput, TouchableOpacity, NativeModules, ActivityIndicator } from 'react-native';

const BrivoSDK = NativeModules.BrivoSDKModule

export default class RedeemPassScreen extends Component {
  constructor(props) {
    super(props);
    this.state = {
      isLoading: false
    };
  }

  onRedeemPassPressed = () => {
    this.setState({
      ...this.state, isLoading: true
    })
    BrivoSDK.redeemPass(this.state.email, this.state.token)
      .then(pass => {
        this.setState({
          ...this.state, isLoading: false
        })
        this.props.navigation.goBack(pass)
      })
      .catch((error) => {
        this.setState({
          ...this.state, isLoading: false
        })
        alert(error)
      });
  }

  render() {
    return (
      <View style={redeemPassStyles.container}>
        <Text style={redeemPassStyles.logo}>BrivoSDK</Text>
        <View style={redeemPassStyles.inputView} >
          <TextInput
            style={redeemPassStyles.inputText}
            placeholder="Email..."
            placeholderTextColor="#003f5c"
            onChangeText={text => this.setState({ email: text })} />
        </View>
        <View style={redeemPassStyles.inputView} >
          <TextInput
            style={redeemPassStyles.inputText}
            placeholder="Token..."
            placeholderTextColor="#003f5c"
            onChangeText={text => this.setState({ token: text })} />
        </View>
        <TouchableOpacity onPress={this.onRedeemPassPressed} style={redeemPassStyles.loginBtn}>
          <Text style={redeemPassStyles.loginText}>REDEEM PASS</Text>
        </TouchableOpacity>
        {this.state.isLoading &&
          <View style={redeemPassStyles.loading}>
            <ActivityIndicator size='large' color="#fb5b5a" />
          </View>
        }
      </View>
    );
  }
}

const redeemPassStyles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#003f5c',
    alignItems: 'center',
    justifyContent: 'center',
  },
  logo: {
    fontWeight: "bold",
    fontSize: 50,
    color: "#fb5b5a",
    marginBottom: 40
  },
  inputView: {
    width: "80%",
    backgroundColor: "#465881",
    borderRadius: 25,
    height: 50,
    marginBottom: 20,
    justifyContent: "center",
    padding: 20
  },
  inputText: {
    height: 50,
    color: "white"
  },
  loginBtn: {
    width: "80%",
    backgroundColor: "#fb5b5a",
    borderRadius: 25,
    height: 50,
    alignItems: "center",
    justifyContent: "center",
    marginTop: 40,
    marginBottom: 10
  },
  loginText: {
    color: "white"
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
});