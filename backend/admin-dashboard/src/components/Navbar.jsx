import { useState, useEffect } from 'react';
import { Menu, Bell, Search, User } from 'lucide-react';
import { getNotifications } from '../api';

export default function Navbar({ onMenuToggle }) {
  const [unreadCount, setUnreadCount] = useState(0);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    getNotifications()
      .then((res) => {
        const items = res.data.results || res.data;
        const unread = Array.isArray(items) ? items.filter((n) => !n.is_read).length : 0;
        setUnreadCount(unread);
      })
      .catch(() => {});
  }, []);

  return (
    <header className="h-16 flex items-center justify-between px-6 glass border-b border-dashboard-border">
      {/* Left */}
      <div className="flex items-center gap-4">
        <button
          onClick={onMenuToggle}
          className="lg:hidden p-2 rounded-lg text-dashboard-text-muted hover:text-white hover:bg-white/10 transition-all"
        >
          <Menu size={20} />
        </button>
        <div className="hidden md:flex items-center gap-2">
          <h2 className="text-lg font-semibold text-white">
            Saral Sewa <span className="text-nepal-red">Admin</span>
          </h2>
          <span className="text-[10px] bg-nepal-red/20 text-nepal-red px-2 py-0.5 rounded-full font-semibold">
            v1.0
          </span>
        </div>
      </div>

      {/* Center - Search */}
      <div className="hidden md:flex items-center max-w-sm w-full mx-4">
        <div className="relative w-full">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-dashboard-text-muted" />
          <input
            type="text"
            placeholder="Search..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-dashboard-card border border-dashboard-border rounded-lg pl-10 pr-4 py-2 text-sm text-dashboard-text placeholder-dashboard-text-muted focus:outline-none focus:border-nepal-red/50 focus:ring-1 focus:ring-nepal-red/30 transition-all"
          />
        </div>
      </div>

      {/* Right */}
      <div className="flex items-center gap-3">
        {/* Notifications bell */}
        <button className="relative p-2 rounded-lg text-dashboard-text-muted hover:text-white hover:bg-white/10 transition-all">
          <Bell size={20} />
          {unreadCount > 0 && (
            <span className="absolute -top-0.5 -right-0.5 w-5 h-5 bg-nepal-red text-white text-[10px] font-bold rounded-full flex items-center justify-center animate-pulse">
              {unreadCount > 9 ? '9+' : unreadCount}
            </span>
          )}
        </button>

        {/* Profile */}
        <div className="flex items-center gap-2 pl-3 border-l border-dashboard-border">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-nepal-red to-nepal-blue flex items-center justify-center">
            <User size={16} className="text-white" />
          </div>
          <div className="hidden sm:block">
            <p className="text-sm font-medium text-white leading-tight">Admin</p>
            <p className="text-[10px] text-dashboard-text-muted">Super Admin</p>
          </div>
        </div>
      </div>
    </header>
  );
}
