from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.admin_site import AdminSite


T = TypeVar("T", bound="GetV1AdminSiteResponse200")


@_attrs_define
class GetV1AdminSiteResponse200:
    """
    Attributes:
        site (AdminSite | None):
        enabled (bool): Whether the `product_admin_site` switch is on (sites answer and sign in).
        object_ (Literal['admin_site'] | Unset):
    """

    site: AdminSite | None
    enabled: bool
    object_: Literal["admin_site"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.admin_site import AdminSite

        site: dict[str, Any] | None
        if isinstance(self.site, AdminSite):
            site = self.site.to_dict()
        else:
            site = self.site

        enabled = self.enabled

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "site": site,
                "enabled": enabled,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["admin_site"] | Unset, d.pop("object", UNSET))
        if object_ != "admin_site" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'admin_site', got '{object_}'")

        get_v1_admin_site_response_200 = cls(
            site=site,
            enabled=enabled,
            object_=object_,
        )

        get_v1_admin_site_response_200.additional_properties = d
        return get_v1_admin_site_response_200

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
