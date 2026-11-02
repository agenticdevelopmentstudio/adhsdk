from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.provider_connection_auth_scheme import ProviderConnectionAuthScheme
from ..models.provider_connection_auth_type import ProviderConnectionAuthType
from ..types import UNSET, Unset

T = TypeVar("T", bound="ProviderConnectionAuth")


@_attrs_define
class ProviderConnectionAuth:
    """
    Attributes:
        type_ (ProviderConnectionAuthType):
        header (str | Unset): header auth: the header name (e.g. api-key)
        scheme (ProviderConnectionAuthScheme | Unset):
        region (str | Unset): sigv4 (reserved)
        token_url (str | Unset): oauth2 (reserved)
    """

    type_: ProviderConnectionAuthType
    header: str | Unset = UNSET
    scheme: ProviderConnectionAuthScheme | Unset = UNSET
    region: str | Unset = UNSET
    token_url: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        type_ = self.type_.value

        header = self.header

        scheme: str | Unset = UNSET
        if not isinstance(self.scheme, Unset):
            scheme = self.scheme.value

        region = self.region

        token_url = self.token_url

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "type": type_,
            }
        )
        if header is not UNSET:
            field_dict["header"] = header
        if scheme is not UNSET:
            field_dict["scheme"] = scheme
        if region is not UNSET:
            field_dict["region"] = region
        if token_url is not UNSET:
            field_dict["tokenUrl"] = token_url

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        type_ = ProviderConnectionAuthType(d.pop("type"))

        header = d.pop("header", UNSET)

        _scheme = d.pop("scheme", UNSET)
        scheme: ProviderConnectionAuthScheme | Unset
        if isinstance(_scheme, Unset):
            scheme = UNSET
        else:
            scheme = ProviderConnectionAuthScheme(_scheme)

        region = d.pop("region", UNSET)

        token_url = d.pop("tokenUrl", UNSET)

        provider_connection_auth = cls(
            type_=type_,
            header=header,
            scheme=scheme,
            region=region,
            token_url=token_url,
        )

        provider_connection_auth.additional_properties = d
        return provider_connection_auth

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
