import { AlertProvider } from './alert-provider.interface.js';
import { 
  fetchActiveAlerts as orefFetchActiveAlerts,
  fetchHistoricalAlerts as orefFetchHistoricalAlerts,
  fetchAlertAreas as orefFetchAlertAreas
} from '../services/oref.service.js';

/**
 * OREF (Home Front Command) implementation of AlertProvider
 */
export class OrefAlertProvider extends AlertProvider {
  async fetchActiveAlerts() {
    return orefFetchActiveAlerts();
  }

  async fetchHistoricalAlerts() {
    return orefFetchHistoricalAlerts();
  }

  async fetchAlertAreas() {
    return orefFetchAlertAreas();
  }
}