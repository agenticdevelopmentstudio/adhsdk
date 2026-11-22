from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1SystemOperatorAccessResponse200DataItem")


@_attrs_define
class GetV1SystemOperatorAccessResponse200DataItem:
    """
    Attributes:
        id (UUID):
        at (str): Postgres timestamptz text, the transaction's start
        operator_account_id (UUID):
        token_id (None | str):
        method (str):
        path (str):
        route (None | str): The matched route pattern
        target_ecosystem_id (None | UUID):
        request_id (None | str):
        ip (None | str):
        user_agent (None | str):
        object_ (Literal['system.operator_access'] | Unset):
    """

    id: UUID
    at: str
    operator_account_id: UUID
    token_id: None | str
    method: str
    path: str
    route: None | str
    target_ecosystem_id: None | UUID
    request_id: None | str
    ip: None | str
    user_agent: None | str
    object_: Literal["system.operator_access"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        at = self.at

        operator_account_id = str(self.operator_account_id)

        token_id: None | str
        token_id = self.token_id

        method = self.method

        path = self.path

        route: None | str
        route = self.route

        target_ecosystem_id: None | str
        if isinstance(self.target_ecosystem_id, UUID):
            target_ecosystem_id = str(self.target_ecosystem_id)
        else:
            target_ecosystem_id = self.target_ecosystem_id

        request_id: None | str
        request_id = self.request_id

        ip: None | str
        ip = self.ip

        user_agent: None | str
        user_agent = self.user_agent

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "at": at,
                "operator_account_id": operator_account_id,
                "token_id": token_id,
                "method": method,
                "path": path,
                "route": route,
                "target_ecosystem_id": target_ecosystem_id,
                "request_id": request_id,
                "ip": ip,
                "user_agent": user_agent,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        at = d.pop("at")

        operator_account_id = UUID(d.pop("operator_account_id"))

        def _parse_token_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        token_id = _parse_token_id(d.pop("token_id"))

        method = d.pop("method")

        path = d.pop("path")

        def _parse_route(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        route = _parse_route(d.pop("route"))

        def _parse_target_ecosystem_id(data: object) -> None | UUID:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                target_ecosystem_id_type_0 = UUID(data)

                return target_ecosystem_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | UUID, data)

        target_ecosystem_id = _parse_target_ecosystem_id(d.pop("target_ecosystem_id"))

        def _parse_request_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        request_id = _parse_request_id(d.pop("request_id"))

        def _parse_ip(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        ip = _parse_ip(d.pop("ip"))

        def _parse_user_agent(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        user_agent = _parse_user_agent(d.pop("user_agent"))

        object_ = cast(Literal["system.operator_access"] | Unset, d.pop("object", UNSET))
        if object_ != "system.operator_access" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'system.operator_access', got '{object_}'")

        get_v1_system_operator_access_response_200_data_item = cls(
            id=id,
            at=at,
            operator_account_id=operator_account_id,
            token_id=token_id,
            method=method,
            path=path,
            route=route,
            target_ecosystem_id=target_ecosystem_id,
            request_id=request_id,
            ip=ip,
            user_agent=user_agent,
            object_=object_,
        )

        get_v1_system_operator_access_response_200_data_item.additional_properties = d
        return get_v1_system_operator_access_response_200_data_item

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
