from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.admin_site import AdminSite


T = TypeVar("T", bound="AdminSiteState")


@_attrs_define
class AdminSiteState:
    """
    Attributes:
        site (AdminSite | None):
        enabled (bool): Whether the `product_admin_site` switch is on (sites answer and sign in).
        content_gated (bool): Whether content enforcement is on (`app_rls.content_enforced()`): the hub reads only a
            product's house rows, never what its customers own.
    """

    site: AdminSite | None
    enabled: bool
    content_gated: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.admin_site import AdminSite

        site: dict[str, Any] | None
        if isinstance(self.site, AdminSite):
            site = self.site.to_dict()
        else:
            site = self.site

        enabled = self.enabled

        content_gated = self.content_gated

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "site": site,
                "enabled": enabled,
                "content_gated": content_gated,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.admin_site import AdminSite

        d = dict(src_dict)

        def _parse_site(data: object) -> AdminSite | None:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                site_type_1 = AdminSite.from_dict(data)

                return site_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(AdminSite | None, data)

        site = _parse_site(d.pop("site"))

        enabled = d.pop("enabled")

        content_gated = d.pop("content_gated")

        admin_site_state = cls(
            site=site,
            enabled=enabled,
            content_gated=content_gated,
        )

        admin_site_state.additional_properties = d
        return admin_site_state

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
