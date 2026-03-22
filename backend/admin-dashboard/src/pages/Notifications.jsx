import { useState, useEffect } from 'react';
import { getNotifications, markNotificationRead, deleteNotification, checkExpiry } from '../api';
import { Bell, Loader2, Trash2, Check, AlertTriangle, Info, Clock, Shield, RefreshCw } from 'lucide-react';

const typeConfig = {
  expiry_warning: { icon: AlertTriangle, color: 'text-yellow-400', bgColor: 'bg-yellow-500/10', label: 'Expiry Warning' },
  application_update: { icon: Clock, color: 'text-blue-400', bgColor: 'bg-blue-500/10', label: 'Application Update' },
  system: { icon: Shield, color: 'text-nepal-red', bgColor: 'bg-nepal-red/10', label: 'System Alert' },
  info: { icon: Info, color: 'text-emerald-400', bgColor: 'bg-emerald-500/10', label: 'Information' },
};

export default function Notifications() {
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [checking, setChecking] = useState(false);
  const [filter, setFilter] = useState('all');

  const fetchNotifications = () => {
    setLoading(true);
    getNotifications()
      .then((res) => {
        const d = res.data;
        setNotifications(d.results || d);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  };

  useEffect(() => { fetchNotifications(); }, []);

  const handleMarkRead = async (id) => {
    try {
      await markNotificationRead(id);
      setNotifications(notifications.map((n) =>
        n.id === id ? { ...n, is_read: true } : n
      ));
    } catch {
      alert('Failed to mark as read');
    }
  };

  const handleDelete = async (id) => {
    try {
      await deleteNotification(id);
      setNotifications(notifications.filter((n) => n.id !== id));
    } catch {
      alert('Failed to delete notification');
    }
  };

  const handleCheckExpiry = async () => {
    setChecking(true);
    try {
      const res = await checkExpiry();
      alert(`Expiry check complete!\n• ${res.data.expiring_documents} expiring documents\n• ${res.data.notifications_created} new notifications\n• ${res.data.expired_documents_updated} expired documents updated`);
      fetchNotifications();
    } catch {
      alert('Failed to run expiry check');
    } finally {
      setChecking(false);
    }
  };

  const filtered = notifications.filter((n) => {
    if (filter === 'all') return true;
    if (filter === 'unread') return !n.is_read;
    return n.notification_type === filter;
  });

  const unreadCount = notifications.filter((n) => !n.is_read).length;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white">Notifications</h1>
          <p className="text-dashboard-text-muted text-sm mt-1">
            {unreadCount > 0 ? `${unreadCount} unread notification${unreadCount > 1 ? 's' : ''}` : 'All caught up!'}
          </p>
        </div>
        <button
          onClick={handleCheckExpiry}
          disabled={checking}
          className="flex items-center gap-2 px-4 py-2 rounded-lg bg-gradient-to-r from-nepal-red to-nepal-red-dark text-white text-sm font-medium hover:shadow-lg hover:shadow-nepal-red/25 disabled:opacity-50 transition-all"
        >
          <RefreshCw size={16} className={checking ? 'animate-spin' : ''} />
          Check Expiring Documents
        </button>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-2 flex-wrap">
        {[
          { key: 'all', label: 'All' },
          { key: 'unread', label: 'Unread' },
          { key: 'expiry_warning', label: 'Expiry Warnings' },
          { key: 'application_update', label: 'App Updates' },
          { key: 'system', label: 'System' },
          { key: 'info', label: 'Info' },
        ].map(({ key, label }) => (
          <button
            key={key}
            onClick={() => setFilter(key)}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
              filter === key
                ? 'bg-nepal-red text-white'
                : 'bg-dashboard-card text-dashboard-text-muted hover:text-white border border-dashboard-border'
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="flex justify-center py-20">
          <Loader2 size={40} className="animate-spin text-nepal-red" />
        </div>
      ) : filtered.length === 0 ? (
        <div className="glass rounded-xl p-12 text-center animate-fade-in">
          <Bell size={48} className="mx-auto text-dashboard-text-muted mb-4 opacity-30" />
          <p className="text-dashboard-text-muted">No notifications found.</p>
        </div>
      ) : (
        <div className="space-y-3">
          {filtered.map((notif) => {
            const cfg = typeConfig[notif.notification_type] || typeConfig.info;
            const NotifIcon = cfg.icon;
            return (
              <div
                key={notif.id}
                className={`glass rounded-xl p-4 animate-fade-in transition-all hover:border-white/10 ${
                  !notif.is_read ? 'border-l-2 border-l-nepal-red' : 'opacity-75'
                }`}
              >
                <div className="flex items-start gap-4">
                  <div className={`w-10 h-10 rounded-xl ${cfg.bgColor} flex items-center justify-center flex-shrink-0`}>
                    <NotifIcon size={20} className={cfg.color} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-4">
                      <div>
                        <h4 className="text-white font-medium text-sm">{notif.title}</h4>
                        <p className="text-dashboard-text-muted text-sm mt-1">{notif.message}</p>
                        <div className="flex items-center gap-3 mt-2">
                          <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${cfg.bgColor} ${cfg.color}`}>
                            {cfg.label}
                          </span>
                          {notif.user_name && notif.user_name !== 'System' && (
                            <span className="text-xs text-dashboard-text-muted">• {notif.user_name}</span>
                          )}
                          <span className="text-xs text-dashboard-text-muted">
                            • {new Date(notif.created_at).toLocaleString()}
                          </span>
                        </div>
                      </div>
                      <div className="flex items-center gap-1 flex-shrink-0">
                        {!notif.is_read && (
                          <button
                            onClick={() => handleMarkRead(notif.id)}
                            className="p-1.5 rounded-lg text-dashboard-text-muted hover:text-emerald-400 hover:bg-emerald-500/10 transition-all"
                            title="Mark as read"
                          >
                            <Check size={16} />
                          </button>
                        )}
                        <button
                          onClick={() => handleDelete(notif.id)}
                          className="p-1.5 rounded-lg text-dashboard-text-muted hover:text-nepal-red hover:bg-nepal-red/10 transition-all"
                          title="Delete"
                        >
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
