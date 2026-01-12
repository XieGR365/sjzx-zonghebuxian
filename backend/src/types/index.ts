export interface Record {
  id?: number;
  record_number: string;
  datacenter_name: string;
  idc_requirement_number?: string;
  yes_ticket_number?: string;
  execution_date?: string;
  user_unit?: string;
  purpose?: string;
  cable_type?: string;
  operator?: string;
  circuit_number?: string;
  contact_person?: string;
  start_port?: string;
  hop1?: string;
  hop2?: string;
  hop3?: string;
  hop4?: string;
  hop5?: string;
  end_port?: string;
  user_cabinet?: string;
  label_complete?: number;
  cable_standard?: number;
  remark?: string;
  created_at?: string;
  updated_at?: string;
}

export interface QueryParams {
  datacenter_name?: string;
  record_number?: string;
  circuit_number?: string;
  start_port?: string;
  end_port?: string;
  user_cabinet?: string;
  operator?: string;
  cable_type?: string;
  idc_requirement_number?: string;
  yes_ticket_number?: string;
  user_unit?: string;
  start_date?: string;
  end_date?: string;
  cable_standard?: number;
  sort_field?: string;
  sort_order?: 'asc' | 'desc';
  page?: number;
  page_size?: number;
}

export interface QueryResult {
  data: Record[];
  total: number;
  page: number;
  page_size: number;
}
