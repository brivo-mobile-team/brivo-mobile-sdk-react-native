import * as React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { GestureHandlerRootView } from "react-native-gesture-handler";

const Stack = createStackNavigator();
import PassesScreen from './PassesScreen';
import RedeemPassScreen from './RedeemPassScreen';

const App = () => {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <NavigationContainer>
        <Stack.Navigator
        detachInactiveScreens={false}
        >
          <Stack.Screen name="PassesScreen" component={PassesScreen} />
          <Stack.Screen name="RedeemPassScreen" component={RedeemPassScreen} />
        </Stack.Navigator>
      </NavigationContainer>
    </GestureHandlerRootView>
  );
};

export default App;