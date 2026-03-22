import { NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard, Users, FileText, ClipboardList,
  Bell, LogOut, ChevronLeft, ChevronRight, Shield
} from 'lucide-react';

const navItems = [
  { to: '/', label: 'Dashboard', icon: LayoutDashboard },
  { to: '/users', label: 'Users', icon: Users },
  { to: '/documents', label: 'Documents', icon: FileText },
  { to: '/applications', label: 'Applications', icon: ClipboardList },
  { to: '/notifications', label: 'Notifications', icon: Bell },
];

export default function Sidebar({ isOpen, onToggle }) {
  const navigate = useNavigate();

  const handleLogout = () => {
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
    navigate('/login');
  };

  return (
    <aside
      className={`${
        isOpen ? 'w-64' : 'w-20'
      } transition-all duration-300 ease-in-out flex flex-col bg-gradient-to-b from-[#0C1222] to-[#162032] border-r border-dashboard-border relative`}
    >
      {/* Logo */}
      <div className="flex items-center gap-3 px-5 py-6 border-b border-dashboard-border">
        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-nepal-red to-nepal-blue flex items-center justify-center flex-shrink-0">
          <Shield className="w-5 h-5 text-white" />
        </div>
        {isOpen && (
          <div className="animate-fade-in">
            <h1 className="text-lg font-bold text-white leading-tight">Saral Sewa</h1>
            <p className="text-[10px] text-nepal-red font-medium tracking-wider uppercase">Admin Panel</p>
          </div>
        )}
      </div>

      {/* Toggle */}
      <button
        onClick={onToggle}
        className="absolute -right-3 top-20 w-6 h-6 rounded-full bg-dashboard-card border border-dashboard-border flex items-center justify-center text-dashboard-text-muted hover:text-white hover:bg-nepal-red transition-all duration-200 z-10"
      >
        {isOpen ? <ChevronLeft size={14} /> : <ChevronRight size={14} />}
      </button>

      {/* Navigation */}
      <nav className="flex-1 py-4 px-3 space-y-1">
        {isOpen && (
          <p className="text-[10px] uppercase tracking-widest text-dashboard-text-muted px-3 mb-3 font-semibold">
            Menu
          </p>
        )}
        {navItems.map(({ to, label, icon: Icon }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all duration-200 group ${
                isActive
                  ? 'bg-gradient-to-r from-nepal-red/20 to-nepal-blue/10 text-white border-l-2 border-nepal-red'
                  : 'text-dashboard-text-muted hover:text-white hover:bg-white/5'
              }`
            }
          >
            <Icon size={20} className="flex-shrink-0 group-hover:scale-110 transition-transform" />
            {isOpen && <span className="text-sm font-medium">{label}</span>}
          </NavLink>
        ))}
      </nav>

      {/* Logout */}
      <div className="p-3 border-t border-dashboard-border">
        <button
          onClick={handleLogout}
          className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-dashboard-text-muted hover:text-nepal-red hover:bg-nepal-red/10 transition-all duration-200 w-full"
        >
          <LogOut size={20} className="flex-shrink-0" />
          {isOpen && <span className="text-sm font-medium">Logout</span>}
        </button>
      </div>
    </aside>
  );
}
